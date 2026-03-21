const {
  PrismaClient,
  ApprovalMode,
  GameStatus,
  JoinRequestStatus,
  Prisma,
} = require("@prisma/client");

const prisma = new PrismaClient();

const MAX_RETRIES = 3;

async function joinGame(req, res, next) {
  const gameId = req.params.gameId;
  const userId = req.user.id;
  const message = typeof req.body.message === "string" ? req.body.message.trim() : null;

  if (message && message.length > 300) {
    return res.status(400).json({
      error: "JOIN_MESSAGE_TOO_LONG",
      message: "Join message must be 300 characters or fewer.",
    });
  }

  for (let attempt = 1; attempt <= MAX_RETRIES; attempt += 1) {
    try {
      const result = await prisma.$transaction(
        async (tx) => {
          const now = new Date();

          const game = await tx.game.findUnique({
            where: { id: gameId },
            select: {
              id: true,
              hostId: true,
              approvalMode: true,
              status: true,
              startAt: true,
              availableSpots: true,
            },
          });

          if (!game) {
            return {
              httpStatus: 404,
              body: {
                error: "GAME_NOT_FOUND",
                message: "Game does not exist.",
              },
            };
          }

          if (game.hostId === userId) {
            return {
              httpStatus: 400,
              body: {
                error: "HOST_CANNOT_JOIN_OWN_GAME",
                message: "Host cannot join their own game.",
              },
            };
          }

          if (game.status === GameStatus.CANCELLED || game.status === GameStatus.COMPLETED) {
            return {
              httpStatus: 409,
              body: {
                error: "GAME_NOT_JOINABLE",
                message: "Game is no longer joinable.",
              },
            };
          }

          if (game.startAt <= now) {
            return {
              httpStatus: 409,
              body: {
                error: "GAME_ALREADY_STARTED",
                message: "Game has already started.",
              },
            };
          }

          if (game.status === GameStatus.FULL || game.availableSpots <= 0) {
            return {
              httpStatus: 409,
              body: {
                error: "GAME_FULL",
                message: "No available spots remain.",
              },
            };
          }

          const existingRequest = await tx.joinRequest.findUnique({
            where: {
              gameId_userId: {
                gameId,
                userId,
              },
            },
            select: {
              id: true,
              status: true,
            },
          });

          if (existingRequest) {
            return {
              httpStatus: 409,
              body: {
                error: "JOIN_REQUEST_ALREADY_EXISTS",
                message: `User already has a ${existingRequest.status.toLowerCase()} record for this game.`,
              },
            };
          }

          if (game.approvalMode === ApprovalMode.MANUAL) {
            const joinRequest = await tx.joinRequest.create({
              data: {
                gameId,
                userId,
                message,
                status: JoinRequestStatus.PENDING,
              },
            });

            return {
              httpStatus: 201,
              body: {
                joinRequest,
                game: {
                  id: game.id,
                  availableSpots: game.availableSpots,
                  status: game.status,
                },
              },
            };
          }

          const seatUpdate = await tx.game.updateMany({
            where: {
              id: gameId,
              status: GameStatus.OPEN,
              availableSpots: {
                gt: 0,
              },
            },
            data: {
              availableSpots: {
                decrement: 1,
              },
            },
          });

          if (seatUpdate.count === 0) {
            return {
              httpStatus: 409,
              body: {
                error: "GAME_FULL",
                message: "No available spots remain.",
              },
            };
          }

          const updatedGame = await tx.game.findUnique({
            where: { id: gameId },
            select: {
              id: true,
              availableSpots: true,
              status: true,
            },
          });

          if (!updatedGame) {
            throw new Error("Game disappeared during join transaction.");
          }

          if (updatedGame.availableSpots === 0 && updatedGame.status !== GameStatus.FULL) {
            await tx.game.update({
              where: { id: gameId },
              data: { status: GameStatus.FULL },
            });

            updatedGame.status = GameStatus.FULL;
          }

          const joinRequest = await tx.joinRequest.create({
            data: {
              gameId,
              userId,
              message,
              status: JoinRequestStatus.APPROVED,
              approvedAt: now,
              respondedAt: now,
            },
          });

          return {
            httpStatus: 201,
            body: {
              joinRequest,
              game: updatedGame,
            },
          };
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        }
      );

      return res.status(result.httpStatus).json(result.body);
    } catch (error) {
      if (error.code === "P2034" && attempt < MAX_RETRIES) {
        continue;
      }

      return next(error);
    }
  }

  return next(new Error("Join transaction failed after retrying."));
}

module.exports = {
  joinGame,
};
