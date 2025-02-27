-----------------------------------------------------------------------------------
-- SNACKS IMAGE CONFIGURATION
-----------------------------------------------------------------------------------

return {
  {
    "snacks.nvim",
    opts = {
      -- Enable the image functionality
      image = {
        enabled = true,
        term_img_cmd = "img2sixel", -- Use img2sixel for terminal image rendering
        max_width = 100,
        max_height = 40,
        window_overlap = false,
        window = {
          zindex = 1000,
          border = "rounded",
        },
        render = {
          enabled = true,
          auto_markdown_image = true,
          auto_open_preview = true,
          max_width_open_cmd = 140,
          exts = {
            ["png"] = true,
            ["jpg"] = true,
            ["jpeg"] = true,
            ["bmp"] = true,
            ["gif"] = true,
            ["svg"] = true,
            ["webp"] = true,
          },
        },
      },
    },
  },
}