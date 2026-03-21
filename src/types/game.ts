export type SkillLevel = "L1" | "L2" | "L3" | "L4" | "L5";

export type DateFilter = "today" | "tomorrow" | "upcoming";

export type CityFilter =
  | "all"
  | "台北市"
  | "新北市"
  | "桃園市"
  | "新竹市"
  | "台中市"
  | "台南市"
  | "高雄市";

export interface Game {
  id: string;
  city: string;
  district: string;
  venueName: string;
  address: string;
  startAt: string;
  durationMinutes: number;
  fee: number;
  capacity: number;
  joinedCount: number;
  skillRange: {
    min: SkillLevel;
    max: SkillLevel;
  };
  shuttlecock: "羽球" | "比賽球";
  hostName: string;
  note?: string;
}

export interface FilterOption<T extends string> {
  label: string;
  value: T;
}
