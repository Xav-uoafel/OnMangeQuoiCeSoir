module.exports = {
  content: [
    './app/views/**/*.erb',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/assets/stylesheets/**/*.css',
  ],
  theme: {
    extend: {},
  },
  plugins: [],
  input: './app/assets/stylesheets/application.tailwind.css',
  output: './app/assets/builds/tailwind.css'
} 

