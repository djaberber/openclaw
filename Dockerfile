# 1. استخدام نسخة أصغر بكثير (Slim)
FROM node:22-slim

# تثبيت الأدوات الأساسية فقط لتقليل الحجم
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# تثبيت Bun بشكل سريع ومختصر
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# نسخ ملفات التعريف فقط أولاً (للاستفادة من الـ Cache)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# تثبيت الاعتماديات مع تنظيف الـ cache فوراً
RUN pnpm install --frozen-lockfile && pnpm store prune

# نسخ باقي الملفات
COPY . .

# البناء (Build)
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

# تنظيف الملفات غير الضرورية بعد البناء لتقليل الحجم النهائي
RUN rm -rf /root/.npm /root/.bun /root/.local

ENV NODE_ENV=production
RUN chown -R node:node /app
USER node

# تشغيل البوابة
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "lan"]
