export type Activity = {
  id: number;
  action: string;
  detail: string;
  time: string;
  status: "success" | "warning" | "info" | "danger";
  created_at?: string;
  user_name?: string;
};
