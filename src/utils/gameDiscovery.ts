import { CityFilter, DateFilter, Game, SkillLevel } from "../types/game";

const skillOrder: SkillLevel[] = ["L1", "L2", "L3", "L4", "L5"];
const weekDayLabels = ["日", "一", "二", "三", "四", "五", "六"];

function isSameLocalDay(a: Date, b: Date) {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  );
}

function getTomorrow(from: Date) {
  const tomorrow = new Date(from);
  tomorrow.setDate(from.getDate() + 1);
  return tomorrow;
}

export function filterGames(params: {
  games: Game[];
  city: CityFilter;
  date: DateFilter;
  skill: SkillLevel | "all";
}) {
  const { games, city, date, skill } = params;
  const today = new Date();
  const tomorrow = getTomorrow(today);

  return games
    .filter((game) => {
      if (city !== "all" && game.city !== city) {
        return false;
      }

      const gameDate = new Date(game.startAt);
      if (date === "today" && !isSameLocalDay(gameDate, today)) {
        return false;
      }

      if (date === "tomorrow" && !isSameLocalDay(gameDate, tomorrow)) {
        return false;
      }

      if (date === "upcoming") {
        const afterTomorrow = new Date(today);
        afterTomorrow.setDate(today.getDate() + 2);
        afterTomorrow.setHours(0, 0, 0, 0);

        if (gameDate < afterTomorrow) {
          return false;
        }
      }

      if (skill !== "all") {
        const filterIndex = skillOrder.indexOf(skill);
        const minIndex = skillOrder.indexOf(game.skillRange.min);
        const maxIndex = skillOrder.indexOf(game.skillRange.max);

        if (filterIndex < minIndex || filterIndex > maxIndex) {
          return false;
        }
      }

      return true;
    })
    .sort(
      (left, right) =>
        new Date(left.startAt).getTime() - new Date(right.startAt).getTime(),
    );
}

export function formatGameDate(isoString: string) {
  const date = new Date(isoString);
  return `${date.getMonth() + 1}/${date.getDate()} (${weekDayLabels[date.getDay()]})`;
}

export function formatGameTime(isoString: string, durationMinutes: number) {
  const start = new Date(isoString);
  const end = new Date(start.getTime() + durationMinutes * 60 * 1000);

  return `${formatTime(start)} - ${formatTime(end)}`;
}

function formatTime(date: Date) {
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${hours}:${minutes}`;
}

export function formatAvailability(joinedCount: number, capacity: number) {
  const remaining = capacity - joinedCount;

  if (remaining <= 0) {
    return "已滿團";
  }

  return `缺${remaining}人`;
}

export function formatSkillRange(min: SkillLevel, max: SkillLevel) {
  return min === max ? min : `${min} - ${max}`;
}
