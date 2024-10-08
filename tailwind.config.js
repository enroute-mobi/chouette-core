module.exports = {
  purge: {
    content: [
      "./app/helpers/**/*.rb",
      "./app/views/**/*.html.slim",
      "./app/decorators/*/*.rb",
      "./config/initializers/simple_form_bootstrap.rb",
      "./app/facades/*/*.rb",
      "./app/packs/**/*.js",
      "./app/packs/**/*.jsx",
      "./app/inputs/**/*.rb"
    ],
    options: {
      // Whitelisting some classes to avoid purge
      safelist: [/^bg-/, /^text-/, /^border-/]
    }
  },
  theme: {
    extend: {
      colors: {
        'enroute-blue': '#00217C',
        'enroute-chouette': '#5B4072',
        'enroute-chouette-primary': '#08B4C1',
        'enroute-chouette-green': '#70B12B',
        'enroute-chouette-smooth-green': '#AEDD8A',
        'enroute-chouette-red':'#DA2F36',
        'enroute-chouette-orange':'#ED7F00',
        'enroute-chouette-gold':'#FFCC00',
        'enroute-ara': '#DB8100',
        'enroute-ara-yellow': '#F4CD0B',
        'light-blue': '#F0F7FD',
        'light-blue-2': '#A2C0DA',
        'light-blue-3': '#25F0FF',
        'light-blue-4': '#717CA2',
        'blue-custom': '#535AFF',
        'light-grey': '#DFDFDF',
        'light-grey-2': '#4E4E4E',
        'light-grey-3': '#858585',
        'light-brown': '#3B3B3B',
        'grey': '#F0F0F0'
      },
      width: {
        '108': '27rem',
        '120': '30rem',
        '132': '33rem',
        '144': '36rem',
        '156': '39rem',
        '168': '42rem',
       }
    },
  },
  plugins: [],
}
