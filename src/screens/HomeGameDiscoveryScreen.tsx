import { FlatList, Pressable, Text, View } from "react-native";
import { SafeAreaView } from "react-native-safe-area-context";

import { GameCard } from "../components/GameCard";
import { mockGames } from "../data/mockGames";
import { useGameDiscoveryStore } from "../store/useGameDiscoveryStore";
import { CityFilter, DateFilter, FilterOption, SkillLevel } from "../types/game";
import { filterGames } from "../utils/gameDiscovery";

const cityOptions: FilterOption<CityFilter>[] = [
  { label: "全部城市", value: "all" },
  { label: "台北市", value: "台北市" },
  { label: "新北市", value: "新北市" },
  { label: "桃園市", value: "桃園市" },
  { label: "新竹市", value: "新竹市" },
  { label: "台中市", value: "台中市" },
  { label: "台南市", value: "台南市" },
  { label: "高雄市", value: "高雄市" },
];

const dateOptions: FilterOption<DateFilter>[] = [
  { label: "今天", value: "today" },
  { label: "明天", value: "tomorrow" },
  { label: "即將開始", value: "upcoming" },
];

const skillOptions: FilterOption<SkillLevel | "all">[] = [
  { label: "全部程度", value: "all" },
  { label: "L1 入門", value: "L1" },
  { label: "L2 初階", value: "L2" },
  { label: "L3 穩定", value: "L3" },
  { label: "L4 進階", value: "L4" },
  { label: "L5 競技", value: "L5" },
];

export function HomeGameDiscoveryScreen() {
  const selectedCity = useGameDiscoveryStore((state) => state.selectedCity);
  const selectedDate = useGameDiscoveryStore((state) => state.selectedDate);
  const selectedSkill = useGameDiscoveryStore((state) => state.selectedSkill);
  const setSelectedCity = useGameDiscoveryStore((state) => state.setSelectedCity);
  const setSelectedDate = useGameDiscoveryStore((state) => state.setSelectedDate);
  const setSelectedSkill = useGameDiscoveryStore((state) => state.setSelectedSkill);

  const filteredGames = filterGames({
    games: mockGames,
    city: selectedCity,
    date: selectedDate,
    skill: selectedSkill,
  });

  return (
    <SafeAreaView className="flex-1 bg-[#F5F1E8]" edges={["top"]}>
      <FlatList
        data={filteredGames}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <GameCard game={item} />}
        contentContainerStyle={{ paddingHorizontal: 20, paddingBottom: 32 }}
        ListHeaderComponent={
          <View className="bg-[#F5F1E8] pb-5 pt-2">
            <Text className="text-[31px] font-black leading-[36px] text-[#183623]">
              找今天的羽球零打
            </Text>
            <Text className="mt-3 text-base leading-6 text-[#5B6C61]">
              先看地點、時間與程度，再決定要不要報名。篩選列固定在上方，滑列表時不會失去上下文。
            </Text>

            <View className="mt-5 rounded-[26px] border border-[#D8E3D5] bg-[#FBF8F1] p-4">
              {/* Buttons are easier to scan than hidden pickers for a broad age range. */}
              <FilterGroup
                label="城市"
                options={cityOptions}
                selectedValue={selectedCity}
                onSelect={setSelectedCity}
              />
              <FilterGroup
                label="日期"
                options={dateOptions}
                selectedValue={selectedDate}
                onSelect={setSelectedDate}
              />
              <FilterGroup
                label="程度"
                options={skillOptions}
                selectedValue={selectedSkill}
                onSelect={setSelectedSkill}
              />
            </View>

            <View className="mt-5 flex-row items-center justify-between">
              <Text className="text-base font-semibold text-[#294433]">
                {filteredGames.length} 場可報名
              </Text>
              <Text className="text-sm text-[#698070]">
                依開打時間排序
              </Text>
            </View>
          </View>
        }
        // Keep filters visible during scroll so users can refine without losing context.
        stickyHeaderIndices={[0]}
        showsVerticalScrollIndicator={false}
        ItemSeparatorComponent={() => <View className="h-1" />}
        ListEmptyComponent={<EmptyState />}
      />
    </SafeAreaView>
  );
}

function FilterGroup<T extends string>({
  label,
  options,
  selectedValue,
  onSelect,
}: {
  label: string;
  options: FilterOption<T>[];
  selectedValue: T;
  onSelect: (value: T) => void;
}) {
  return (
    <View className="mb-4">
      <Text className="mb-3 text-sm font-semibold tracking-[0.2px] text-[#425546]">
        {label}
      </Text>
      <View className="flex-row flex-wrap">
        {options.map((option) => {
          const isSelected = selectedValue === option.value;

          return (
            <Pressable
              key={option.value}
              className={`mb-2 mr-2 rounded-full border px-4 py-2.5 ${
                isSelected
                  ? "border-[#1E6B42] bg-[#1E6B42]"
                  : "border-[#D7E1D3] bg-[#FFFFFF]"
              }`}
              onPress={() => onSelect(option.value)}
            >
              <Text
                className={`text-sm font-semibold ${
                  isSelected ? "text-white" : "text-[#37513D]"
                }`}
              >
                {option.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}

function EmptyState() {
  return (
    <View className="mt-20 items-center rounded-[28px] border border-dashed border-[#C8D6C7] bg-[#FBF8F1] px-8 py-10">
      <Text className="text-xl font-bold text-[#22382A]">
        目前該地區沒有零打活動
      </Text>
      <Text className="mt-3 text-center text-sm leading-6 text-[#627266]">
        試試切換城市、日期或降低程度限制，通常就能找到附近的新場次。
      </Text>
    </View>
  );
}
