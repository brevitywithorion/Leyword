import { createFileRoute } from "@tanstack/react-router";
import { LeywordApp } from "@/components/leyword-app";

export const Route = createFileRoute("/")({ component: LeywordApp });
