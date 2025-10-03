import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";

export default defineConfig({
  output: "static",
  site: "https://g-structure.github.io",
  base: "/config",
  integrations: [
    starlight({
      title: "WikiGen's Config Documentation",
      description: "Documentation for WikiGen's Nix configuration - modular multi-platform setup",
      prerender: true,
      defaultLocale: "root",
      locales: {
        root: {
          label: "English",
          lang: "en",
        },
      },
      customCss: ["./src/styles/custom.css"],
      // Enable search
      pagefind: true,
      sidebar: [
        {
          label: "Getting Started",
          autogenerate: { directory: "getting-started" },
        },
        {
          label: "Guides",
          items: [
            {
              label: "Development",
              autogenerate: { directory: "guides/development" },
            },
            {
              label: "Deployment",
              autogenerate: { directory: "guides/deployment" },
            },
            {
              label: "Hardware Security",
              autogenerate: { directory: "guides/hardware-security" },
            },
            {
              label: "Secrets Management",
              autogenerate: { directory: "guides/secrets-management" },
            },
          ],
        },
        {
          label: "Architecture",
          autogenerate: { directory: "architecture" },
        },
        {
          label: "Reference",
          autogenerate: { directory: "reference" },
        },
      ],
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/wikigen'
        },
      ],
    }),
  ],
});
