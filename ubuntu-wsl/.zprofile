# Show fastfetch before ~/.zshrc (avoids P10k instant prompt warning)
if [[ -t 1 ]] && command -v fastfetch >/dev/null 2>&1; then
  fastfetch
fi
