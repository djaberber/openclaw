# 1. استخدام نسخة Slim
FROM node:22-slim

# 2. تثبيت الأدوات الأساسية (أضفنا unzip هنا لحل المشكلة)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# 3. تثبيت Bun
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="/root/.bun/bin:${PATH}"

RUN corepack enable

WORKDIR /app

# 4. نسخ ملفات التعريف
COPY package.json pnpm-lock.yaml* pnpm-workspace.yaml* .npmrc* ./
COPY ui/package.json ./ui/package.json
COPY patches ./patches
COPY scripts ./scripts

# 5. تثبيت الاعتماديات
RUN pnpm install --frozen-lockfile

# 6. نسخ باقي الملفات وبناء المشروع
COPY . .
RUN pnpm build
ENV OPENCLAW_PREFER_PNPM=1
RUN pnpm ui:build

ENV NODE_ENV=production
RUN chown -R node:node /app
USER node

# 7. تشغيل البوابة (تأكد من استخدام 0.0.0.0 ليعمل الرابط الخارجي)
CMD ["node", "openclaw.mjs", "gateway", "--allow-unconfigured", "--bind", "0.0.0.0"]
