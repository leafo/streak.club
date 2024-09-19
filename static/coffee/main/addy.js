// Create a container for our effects
const effectsContainer = document.createElement('div');
effectsContainer.id = 'birthday-effects-container';
document.body.appendChild(effectsContainer);

// Styles for the effects, messages, and banner
const style = document.createElement('style');
style.textContent = `
  #birthday-effects-container {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    pointer-events: none;
    z-index: 9999;
    overflow: hidden;
  }
  .birthday-banner {
    position: fixed;
    bottom: 40px;
    left: 0;
    right: 0;
    display: flex;
    justify-content: center;
    z-index: 10000;
  }
  .banner-letter {
    width: 40px;
    height: 50px;
    margin: 0 5px;
    display: flex;
    justify-content: center;
    align-items: center;
    font-size: 24px;
    font-weight: bold;
    color: white;
    text-shadow: 1px 1px 2px rgba(0,0,0,0.5);
    clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%);
    transform-origin: top center;
  }
  .balloon {
    position: absolute;
    animation: float 15s ease-in-out infinite;
  }
  .balloon-string {
    width: 1px;
    height: 100px;
    background-color: #ccc;
    margin: 0 auto;
  }
  .balloon-body {
    width: 60px;
    height: 70px;
    background-color: #ff69b4;
    border-radius: 50% 50% 50% 50% / 40% 40% 60% 60%;
    position: relative;
    margin: 0 auto;
    font-weight: bold;
  }
  .balloon-body::before,
  .balloon-body::after {
    content: '';
    position: absolute;
    width: 20px;
    height: 20px;
    background-color: rgba(255, 255, 255, 0.3);
    border-radius: 50%;
  }
  .balloon-body::before {
    top: 15px;
    left: 10px;
  }
  .balloon-body::after {
    top: 25px;
    left: 15px;
    width: 10px;
    height: 10px;
  }
  .balloon-message {
    position: absolute;
    width: 120px;
    text-align: center;
    font-size: 14px;
    color: #fff;
    -webkit-text-stroke: 4px black;
    paint-order: stroke fill;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%);
  }
  .confetti {
    position: absolute;
    width: 10px;
    height: 10px;
    background-color: #f0f0f0;
    clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
    animation: shoot-up ease-out;
  }
  @keyframes float {
    0%, 100% { transform: translateY(0) rotate(0deg); }
    50% { transform: translateY(-20px) rotate(5deg); }
  }
  @keyframes shoot-up {
    0% { transform: translateY(0) rotate(0deg); }
    100% { transform: translateY(-100vh) rotate(720deg); }
  }
  @media (max-width: 600px) {
    .banner-letter {
      font-size: 16px;
    }
  }
`;
document.head.appendChild(style);

// Function to create the birthday banner
function createBirthdayBanner() {
    const banner = document.createElement('div');
    banner.classList.add('birthday-banner');
    const text = 'HAPPY BIRTHDAY';
    const colors = ['#FF69B4', '#87CEFA', '#9370DB', '#90EE90', '#FFA500', '#40E0D0'];
    
    text.split('').forEach((letter, index) => {
        const letterElement = document.createElement('div');
        letterElement.classList.add('banner-letter');
        letterElement.textContent = letter;
        letterElement.style.backgroundColor = colors[index % colors.length];

        // Calculate position on curve
        const angle = (index / (text.length - 1) - 0.5) * 40;
        const y = Math.abs(angle) * 1;
        letterElement.style.transform = `rotate(${angle}deg) translateY(${y}px)`;
        
        banner.appendChild(letterElement);
    });
    
    effectsContainer.appendChild(banner);
}

// Function to create a balloon with message
function createBalloon() {
    const balloon = document.createElement('div');
    balloon.classList.add('balloon');
    
    const balloonBody = document.createElement('div');
    balloonBody.classList.add('balloon-body');
    
    const balloonString = document.createElement('div');
    balloonString.classList.add('balloon-string');
    
    const message = document.createElement('div');
    message.classList.add('balloon-message');
    message.textContent = 'Happy Birthday Addy!';
    
    balloonBody.appendChild(message);
    balloon.appendChild(balloonBody);
    balloon.appendChild(balloonString);
    
    balloon.style.left = Math.random() * 80 + 10 + '%';
    balloon.style.top = Math.random() * 50 + 25 + '%';
    balloon.style.animationDelay = -Math.random() * 15 + 's';
    
    const hue = Math.floor(Math.random() * 360);
    balloonBody.style.backgroundColor = `hsl(${hue}, 100%, 70%)`;
    
    effectsContainer.appendChild(balloon);
}

// Function to create a single confetti
function createConfetti() {
    const confetti = document.createElement('div');
    confetti.classList.add('confetti');
    confetti.style.left = Math.random() * 100 + 'vw';
    confetti.style.bottom = '0';
    confetti.style.animationDuration = Math.random() * 3 + 2 + 's';
    confetti.style.opacity = Math.random();
    
    const hue = Math.floor(Math.random() * 360);
    confetti.style.backgroundColor = `hsl(${hue}, 100%, 50%)`;

    effectsContainer.appendChild(confetti);

    confetti.addEventListener('animationend', () => confetti.remove());
}

// Create confetti
function createConfettiEffect() {
    for (let i = 0; i < 5; i++) {
        setTimeout(createConfetti, Math.random() * 1000);
    }
}


// Function to stop the effect
function stopEffect() {
    effectsContainer.remove();
    document.removeEventListener('keydown', escapeKeyHandler);
}

// Event listener for Escape key
function escapeKeyHandler(event) {
    if (event.key === 'Escape') {
        stopEffect();
    }
}

// Initialize all effects
export function startBirthday() {
    document.addEventListener('keydown', escapeKeyHandler);


    createBirthdayBanner();
    for (let i = 0; i < 5; i++) {
        createBalloon();
    }
    setInterval(createConfettiEffect, 200);
}
