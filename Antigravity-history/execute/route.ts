import { NextRequest, NextResponse } from "next/server";

export async function GET() {
    return NextResponse.json({
        name: "Shunshi Wellness Agent",
        version: "1.0.0",
        protocol: "FXAP/v1",
        agentId: "futurex.shunshi",
        capabilities: ["text", "scheduling", "personalization"],
        endpoints: {
            manifest: "/api/internal/shunshi/manifest",
            execute: "/api/internal/shunshi/execute",
        },
    });
}

export async function POST(req: NextRequest) {
    try {
        const { message } = await req.json();

        const solarTerms = ["立春", "雨水", "惊蛰", "春分", "清明", "谷雨"];
        const term = solarTerms[Math.floor(Math.random() * solarTerms.length)];

        const output = `🧘 **Shunshi Wellness Agent**\n\nPersonalized plan based on your request:\n> "${message}"\n\n**Current 节气: ${term}**\n\n🌅 **Morning Routine:**\n- Gentle stretching (15 min)\n- Warm water with honey & lemon\n- 5 min breathing meditation\n\n☀️ **Afternoon:**\n- Light walk in nature (20 min)\n- Green tea break\n- Neck & shoulder stretches\n\n🌙 **Evening:**\n- Warm foot soak with herbs\n- Guided meditation (10 min)\n- Lights out by 10:30 PM\n\n🌿 **Seasonal Focus:** Spring liver nourishment`;

        return NextResponse.json({
            output,
            data: {
                solarTerm: term,
                season: "Spring",
                focusArea: "Liver nourishment",
                status: "plan_ready",
            },
        });
    } catch (error) {
        console.error("Shunshi agent error:", error);
        return NextResponse.json(
            { error: "Execution failed" },
            { status: 500 }
        );
    }
}
