import { create } from "zustand";

import { CityFilter, DateFilter, SkillLevel } from "../types/game";

interface GameDiscoveryState {
  selectedCity: CityFilter;
  selectedDate: DateFilter;
  selectedSkill: SkillLevel | "all";
  setSelectedCity: (city: CityFilter) => void;
  setSelectedDate: (date: DateFilter) => void;
  setSelectedSkill: (skill: SkillLevel | "all") => void;
}

export const useGameDiscoveryStore = create<GameDiscoveryState>((set) => ({
  selectedCity: "all",
  selectedDate: "today",
  selectedSkill: "all",
  setSelectedCity: (selectedCity) => set({ selectedCity }),
  setSelectedDate: (selectedDate) => set({ selectedDate }),
  setSelectedSkill: (selectedSkill) => set({ selectedSkill }),
}));
