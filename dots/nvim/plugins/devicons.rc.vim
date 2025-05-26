" kyazdani42/nvim-web-devicons
lua <<EOF
require'nvim-web-devicons'.setup {
 -- your personnal icons can go here (to override)
 -- DevIcon will be appended to `name`
 override = {
  zsh = {
    icon = "",
    color = "#428850",
    name = "Zsh"
  };
  ["js"] = {
      icon = "",
      color = "#cbcb41",
      name = "Js",
    };
 };
}
EOF

