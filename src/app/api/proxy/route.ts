import { NextRequest, NextResponse } from 'next/server';

export async function GET(request: NextRequest) {
  const url = request.nextUrl.searchParams.get('url');
  if (!url) return NextResponse.json({ error: 'Missing url param' }, { status: 400 });

  try {
    const res = await fetch(url, { signal: AbortSignal.timeout(5000) });
    if (!res.ok) {
        return NextResponse.json({ error: `Target responded with ${res.status}` }, { status: res.status });
    }
    const data = await res.json();
    return NextResponse.json(data, { status: 200 });
  } catch (error) {
    console.error("Proxy fetch error:", error);
    return NextResponse.json({ error: 'Failed to fetch target' }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
    const url = request.nextUrl.searchParams.get('url');
    if (!url) return NextResponse.json({ error: 'Missing url param' }, { status: 400 });

    try {
        const res = await fetch(url, { method: 'POST' });
        const data = await res.json();
        return NextResponse.json(data, { status: res.status });
    } catch (error) {
         console.error("Proxy post error:", error);
         return NextResponse.json({ error: 'Failed to post to target' }, { status: 500 });
    }
}
