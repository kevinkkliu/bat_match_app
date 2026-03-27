/*
  Warnings:

  - A unique constraint covering the columns `[lineProviderId]` on the table `User` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE "User" ADD COLUMN     "lineProviderId" VARCHAR(255);

-- CreateIndex
CREATE UNIQUE INDEX "User_lineProviderId_key" ON "User"("lineProviderId");
