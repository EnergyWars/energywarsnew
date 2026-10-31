import { number } from "../format.js";

export const METRICS = [
  { key: "cost", color: "var(--series-cost)", digits: 0, format: (value) => number(value, 0) },
  { key: "spent", color: "var(--series-spent-factor)", digits: 0, format: (value) => number(value, 0) },
  { key: "value", color: "var(--series-gain)", digits: 4, format: (value) => `+${number(value, 2)}` },
  { key: "totalValue", color: "var(--series-spent)", digits: 2, format: (value) => number(value, 2) },
  { key: "efficiency", color: "var(--series-unit-cost)", digits: 4, format: (value) => number(value, 3) },
  { key: "totalEfficiency", color: "var(--series-total)", digits: 4, format: (value) => number(value, 3) },
  { key: "factor", color: "var(--series-level)", digits: 4, format: (value) => `×${number(value, 3)}` },
];

export const METRIC_KEYS = METRICS.map((metric) => metric.key);
export const CHART_METRICS = METRICS;
