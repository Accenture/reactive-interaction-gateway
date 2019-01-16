// See https://docusaurus.io/docs/site-config.html for all the possible
// site configuration options.

/* List of projects/orgs using your project for the users page */
const users = [{
  caption: 'Accenture',
  // You will need to prepend the image path with your baseUrl
  // if it is not '/', like: '/test-site/img/docusaurus.svg'.
  image: 'https://upload.wikimedia.org/wikipedia/commons/c/cd/Accenture.svg',
  infoLink: 'https://www.accenture.com',
  pinned: true,
}, ];

const siteConfig = {
  title: 'Reactive Interaction Gateway',
  tagline: 'Your UI deserves an API, too!',
  url: 'https://accenture.github.io',
  baseUrl: '/reactive-interaction-gateway/',
  projectName: 'reactive-interaction-gateway',
  organizationName: 'Accenture',
  repoUrl: `https://github.com/accenture/reactive-interaction-gateway`,
  headerLinks: [{
      doc: 'intro',
      label: 'Docs'
    },
    {
      href: 'reference/',
      label: 'API Reference'
    },
    // { page: 'help', label: 'Help' },
    // { blog: true, label: 'Blog' },
  ],

  users,

  headerIcon: 'img/icon.svg',
  // footerIcon: 'img/icon+text.svg',
  favicon: 'img/favicon.png',

  colors: {
    primaryColor: "#a89f63", // "#bca71c", //'#c68c3e', //'#293C88', //'#2E8555',
    secondaryColor: "#808080", // "#bc1c49", //'#3972C1', //'#205C3B',
  },

  // This copyright info is used in /core/Footer.js and blog rss/atom feeds.
  copyright: 'Copyright © ' +
    new Date().getFullYear() +
    ' Accenture',

  highlight: {
    // Highlight.js theme to use for syntax highlighting in code blocks
    theme: 'default',
  },

  // Add custom scripts here that would be placed in <script> tags
  scripts: ['https://buttons.github.io/buttons.js'],

  /* On page navigation for the current documentation page */
  onPageNav: 'separate',

  /* Open Graph and Twitter card images */
  // ogImage: 'img/docusaurus.png',
  // twitterImage: 'img/docusaurus.png',

  // You may provide arbitrary config keys to be used as needed by your
  // template.
};

module.exports = siteConfig;
