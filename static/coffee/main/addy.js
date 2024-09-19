// Create a container for our effects
const effectsContainer = document.createElement('div');
effectsContainer.id = 'birthday-effects-container';
document.body.appendChild(effectsContainer);

let counterEl = null

const defaultDoubleRate = 0.25
let doubleRate = defaultDoubleRate

function incrementBalloonsPopped() {
  let balloonsPopped = localStorage.getItem('balloonsPopped');
  if (balloonsPopped === null) {
    balloonsPopped = 0;
  } else {
    balloonsPopped = parseInt(balloonsPopped, 10);
  }
  balloonsPopped += 1;
  localStorage.setItem('balloonsPopped', balloonsPopped);

  if (counterEl) {
    counterEl.innerText = balloonsPopped;
    if (balloonsPopped > 999) {
      counterEl.style.fontSize = '12px';
    }
  }
}

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
    animation: inflate 0.5s ease-out;
    cursor: pointer;
    pointer-events: auto;
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
  @keyframes inflate {
    0% { transform: scale(0); }
    100% { transform: scale(1); }
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
    const text = 'HAPPY BTHDADAY';
    const colors = ['#FF69B4', '#87CEFA', '#9370DB', '#90EE90', '#FFA500', '#40E0D0'];
    
    text.split('').forEach((letter, index) => {
        const letterElement = document.createElement('div');

        if (letter == ' ') {
          counterEl = letterElement
        }

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

    // Add click event listener to pop the balloon
    balloonBody.addEventListener('click', () => {
        popBalloon(balloon);
    });
}

// Function to pop a balloon
function popBalloon(balloon) {
    incrementBalloonsPopped();
    // Play pop sound
    const popSound = new Audio(`data:audio/mp3;base64,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
OFBITF0EqeAGChllhdJaLJYZas/7BSoE6GQDTIootUJkS7C7pokJFFpyIibThFFdslR3LBVBOhqG
2JiFcjjCl1kcY0Mqu21n6xrLxsj6JkakaDgPHpVf7C87mFGVlh5kbWe1Jo4kVMmVCz8tupMgs19T
yMaRACSAFoUIlZ0M7x+2Q4YGvlTVlDAwaDlMQU1FMy4xMDBVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVf/7YMT1AA7VQTvssG3p1qRnvaMOXFVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVf/7QMT2gNBFSzfspG9g
YodiUPCNHVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV
VVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVVV`);
    popSound.play();

    // Create pop effect
    const popEffect = document.createElement('div');
    popEffect.style.position = 'absolute';
    popEffect.style.left = balloon.style.left;
    popEffect.style.top = balloon.style.top;
    popEffect.style.width = '60px';
    popEffect.style.height = '60px';
    popEffect.style.borderRadius = '50%';
    popEffect.style.backgroundColor = balloon.querySelector('.balloon-body').style.backgroundColor;
    popEffect.style.opacity = '0.7';
    popEffect.style.animation = 'pop 0.3s ease-out forwards';

    effectsContainer.appendChild(popEffect);

    // Remove the balloon
    balloon.remove();

    // Remove the pop effect after animation
    setTimeout(() => {
        popEffect.remove();
    }, 300);


    if (Math.random() < doubleRate) {
      createBalloon();
      doubleRate = defaultDoubleRate
    } else {
      doubleRate *= 1.3
    }
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
    clearInterval(createConfettiEffect);
    clearInterval(createBalloon);
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
    setInterval(createBalloon, 5000);
}
