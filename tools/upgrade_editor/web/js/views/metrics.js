import { number, percent } from "../format.js";

export const METRICS = [
  { key: "cost", color: "var(--series-cost)", digits: 0, format: (value) => number(value, 0) },
  { key: "costFactor", color: "var(--series-cost-factor)", digits: 4, format: (value) => `×${number(value, 2)}` },
  { key: "spent", color: "var(--series-spent)", digits: 0, format: (value) => number(value, 0) },
  { key: "spentFactor", color: "var(--series-spent-factor)", digits: 4, format: (value) => `×${number(value, 2)}` },
  { key: "gain", color: "var(--series-gain)", digits: 4, format: (value) => `+${number(value, 4)}` },
  { key: "effect", color: "var(--series-effect)", digits: 4, format: (value) => `×${number(value, 3)}` },
  { key: "single", color: "var(--series-level)", digits: 2, format: percent },
  { key: "total", color: "var(--series-total)", digits: 2, format: percent },
  { key: "benefit", color: "var(--series-benefit)", digits: 2, format: (value) => number(value, 2) },
];

export const METRIC_KEYS = METRICS.map((metric) => metric.key);
