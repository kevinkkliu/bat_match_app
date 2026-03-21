import { Pressable, Text, View } from "react-native";

import { Game } from "../types/game";
import {
  formatAvailability,
  formatGameDate,
  formatGameTime,
  formatSkillRange,
} from "../utils/gameDiscovery";

interface GameCardProps {
  game: Game;
  onPress?: (game: Game) => void;
}

export function GameCard({ game, onPress }: GameCardProps) {
  const availability = formatAvailability(game.joinedCount, game.capacity);
  const isFull = availability === "已滿團";
  const [startTime, endTime] = formatGameTime(
    game.startAt,
    game.durationMinutes,
  ).split(" - ");

  return (
    <Pressable
      className="mb-4 overflow-hidden rounded-[28px] border border-[#D7E1D3] bg-[#FFFDF8]"
      onPress={() => onPress?.(game)}
      style={{
        shadowColor: "#22422D",
        shadowOpacity: 0.08,
        shadowRadius: 16,
        shadowOffset: { width: 0, height: 8 },
        elevation: 4,
      }}
    >
      <View className="flex-row border-b border-[#E7EEE3]">
        {/* Left rail isolates the scheduling signal so users can scan date/time first. */}
        <View className="w-[104px] bg-[#E3F0E5] px-4 py-5">
          <Text className="text-xs font-medium uppercase tracking-[1px] text-[#52715A]">
            {formatGameDate(game.startAt)}
          </Text>
          <Text className="mt-3 text-xl font-black text-[#173321]">
            {startTime}
          </Text>
          <Text className="mt-1 text-sm font-semibold text-[#45604D]">
            至 {endTime}
          </Text>
        </View>

        <View className="flex-1 px-5 py-5">
          <View className="flex-row items-start justify-between">
            <View className="mr-4 flex-1">
              <Text className="text-xl font-bold text-[#173321]">
                {game.venueName}
              </Text>
              <Text className="mt-1 text-sm leading-5 text-[#5F6E65]">
                {game.city}
                {" · "}
                {game.district}
              </Text>
              <Text className="mt-2 text-sm leading-5 text-[#415147]">
                {game.address}
              </Text>
            </View>

            <View
              className={`rounded-full px-3 py-1.5 ${
                isFull ? "bg-[#FCE9E5]" : "bg-[#EEF6E7]"
              }`}
            >
              <Text
                className={`text-xs font-semibold ${
                  isFull ? "text-[#B24A34]" : "text-[#2E7D32]"
                }`}
              >
                {availability}
              </Text>
            </View>
          </View>

          <View className="mt-5 flex-row flex-wrap">
            <MetaPill label={`NT$ ${game.fee}`} />
            <MetaPill label={formatSkillRange(game.skillRange.min, game.skillRange.max)} />
            <MetaPill label={game.shuttlecock} />
          </View>

          {!!game.note && (
            <Text className="mt-4 text-sm leading-5 text-[#506056]">
              {game.note}
            </Text>
          )}
        </View>
      </View>
    </Pressable>
  );
}

function MetaPill({ label }: { label: string }) {
  return (
    <View className="mb-2 mr-2 rounded-full bg-[#F1F4EC] px-3 py-2">
      <Text className="text-xs font-semibold tracking-[0.3px] text-[#37513D]">
        {label}
      </Text>
    </View>
  );
}
