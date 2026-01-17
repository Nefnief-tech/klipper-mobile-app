import { prisma } from '@/lib/prisma';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const printers = await prisma.printer.findMany();
    return NextResponse.json(printers);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to fetch printers' }, { status: 500 });
  }
}

export async function POST(request: Request) {
  try {
    const { name, ip } = await request.json();
    const printer = await prisma.printer.create({
      data: { name, ip },
    });
    return NextResponse.json(printer);
  } catch (error) {
    return NextResponse.json({ error: 'Failed to create printer' }, { status: 500 });
  }
}
