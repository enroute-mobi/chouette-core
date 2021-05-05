const { NODE_ENV } = process.env

export const isDev = NODE_ENV == 'development'
export const isProd = NODE_ENV == 'production'
