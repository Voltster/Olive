// Olive Landing Page Interactive Scripts

document.addEventListener('DOMContentLoaded', () => {
  // 1. One-click copy for Homebrew command
  const copyBtn = document.getElementById('copyBtn');
  const brewCode = document.getElementById('brewCode');
  const brewBox = document.getElementById('brewBox');

  if (copyBtn && brewCode) {
    const copyHandler = async () => {
      const textToCopy = brewCode.textContent.trim();
      try {
        await navigator.clipboard.writeText(textToCopy);
        const tooltip = copyBtn.querySelector('.copy-tooltip');
        if (tooltip) {
          tooltip.classList.add('show');
          setTimeout(() => {
            tooltip.classList.remove('show');
          }, 2000);
        }
      } catch (err) {
        console.error('Failed to copy: ', err);
      }
    };

    copyBtn.addEventListener('click', copyHandler);
    brewBox.addEventListener('click', (e) => {
      if (e.target !== copyBtn) {
        copyHandler();
      }
    });
  }

  // 2. Interactive Navigation Pills inside the mockup window
  const pills = document.querySelectorAll('.window-nav-pills .pill');
  pills.forEach((pill) => {
    pill.addEventListener('click', () => {
      pills.forEach((p) => p.classList.remove('active'));
      pill.classList.add('active');
    });
  });
});
