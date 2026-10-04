import { createFileRoute } from "@tanstack/react-router";
import { WoWdleApp } from "@/components/wowdle-app";

export const Route = createFileRoute("/")({ component: WoWdleApp });
