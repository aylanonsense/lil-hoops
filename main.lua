-- Render constants
local GAME_WIDTH = 192
local GAME_HEIGHT = 192
local RENDER_SCALE = 3
local DRAW_PHYSICS_OBJECTS = false

-- Game constants
local SHOT_X = 25
local SHOT_Y = 140
local BALL_BOUNCINESS = 0.7
local GRAVITY = 200

-- Game variables
local world
local ball
local hoop
local backboard
local flashes
local shotStep
local shotTimer
local shotAngle
local shotPower
local celebrationTimer

-- Assets
local ballImage
local hoopImage
local flashImage
local aimSound
local powerSound
local shootSound
local bounceSound
local flashSound

-- Initializes the game
function love.load()
  -- Load assets
  ballImage = love.graphics.newImage('img/ball.png')
  hoopImage = love.graphics.newImage('img/hoop.png')
  flashImage = love.graphics.newImage('img/flash.png')
  ballImage:setFilter('nearest', 'nearest')
  hoopImage:setFilter('nearest', 'nearest')
  flashImage:setFilter('nearest', 'nearest')
  aimSound = love.audio.newSource('sfx/aim.wav', 'static')
  powerSound = love.audio.newSource('sfx/power.wav', 'static')
  shootSound = love.audio.newSource('sfx/shoot.wav', 'static')
  bounceSound = love.audio.newSource('sfx/bounce.wav', 'static')
  flashSound = love.audio.newSource('sfx/flash.wav', 'static')

  -- Initialize game variables
  shotStep = 'aim'
  shotTimer = 0.00
  shotAngle = 0
  shotPower = 0
  celebrationTimer = 0.00

  -- Set up the physics world
  love.physics.setMeter(10)
  world = love.physics.newWorld(0, GRAVITY, true)
  world:setCallbacks(onCollide)
 
  -- Create the ball
  ball = createCircle(SHOT_X, SHOT_Y, 8)
  ball.fixture:setRestitution(BALL_BOUNCINESS)

  -- Create the hoop (it's actually just two static circles, one for each side of the hoop)
  hoop = {
    createCircle(139, 82, 2, true),
    createCircle(163, 82, 2, true)
  }

  -- Create the backboard
  backboard = createRectangle(170, 65, 5, 50, true)

  -- Create an empty array for camera flashes
  flashes = {}
end

-- Updates the game state
function love.update(dt)
  -- Update timers
  shotTimer = shotTimer + dt
  celebrationTimer = math.max(0.00, celebrationTimer - dt)

  -- Update the physics simulation
  world:update(dt)

  -- Aim the ball and select power
  local t = shotTimer % 2.00
  if shotStep == 'aim' then
    if t < 1.00 then
      shotAngle = -t * math.pi / 2
    else
      shotAngle = (t - 2.00) * math.pi / 2
    end
  elseif shotStep == 'power' then
    if t < 1.00 then
      shotPower = t
    else
      shotPower = 2.00 - t
    end
  end

  -- Keep the ball in one place until it's been shot
  if shotStep ~= 'shoot' then
    ball.body:setPosition(SHOT_X, SHOT_Y)
    ball.body:setLinearVelocity(0, 0)
  end

  -- Check for baskets
  local dx = ball.body:getX() - (hoop[1].body:getX() + hoop[2].body:getX()) / 2
  local dy = ball.body:getY() - (hoop[1].body:getY() + hoop[2].body:getY()) / 2
  local dist = math.sqrt(dx * dx + dy * dy)
  if dist < 3 and celebrationTimer <= 0.00 then
    celebrationTimer = 1.00
    love.audio.play(flashSound:clone())
  end

  -- Camera flashes!
  if celebrationTimer > 0.00 then
    for _, flash in ipairs(flashes) do
      flash.timeToDisappear = math.max(0.00, flash.timeToDisappear - dt)
    end
    table.insert(flashes, {
      x = math.random(10, GAME_WIDTH - 10),
      y = math.random(10, GAME_HEIGHT - 10),
      timeToDisappear = 0.10
    })
  else
    flashes = {}
  end
end

-- Renders the game
function love.draw()
  -- Scale and crop the screen
  love.graphics.setScissor(0, 0, RENDER_SCALE * GAME_WIDTH, RENDER_SCALE * GAME_HEIGHT)
  love.graphics.scale(RENDER_SCALE, RENDER_SCALE)
  if celebrationTimer > 0.00 then
    love.graphics.clear(253 / 255, 217 / 255, 37 / 255)
  else
    love.graphics.clear(252 / 255, 147 / 255, 1 / 255)
  end
  love.graphics.setColor(1, 1, 1)

  -- Draw the camera flashes
  for _, flash in ipairs(flashes) do
    if flash.timeToDisappear > 0.00 then
      love.graphics.draw(flashImage, flash.x - 5, flash.y - 7)
    end
  end

  -- Draw the ball
  love.graphics.draw(ballImage, ball.body:getX() - 8, ball.body:getY() - 8)

  -- Draw the hoop
  love.graphics.draw(hoopImage, 138, 40)

  -- Draw aiming reticle
  if shotStep ~= 'shoot' then
    love.graphics.setColor(91 / 255, 20 / 255, 3 / 255)
    local increment = 5 + 8 * shotPower
    for dist = 8 + increment, 8 + 5 * increment, increment do
      love.graphics.rectangle('fill', SHOT_X + math.cos(shotAngle) * dist - 1, SHOT_Y + math.sin(shotAngle) * dist - 1, 2, 2)
    end
  end

  -- Draw the physics objects (for debugging)
  if DRAW_PHYSICS_OBJECTS then
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('fill', ball.body:getX(), ball.body:getY(), ball.shape:getRadius())
    love.graphics.circle('fill', hoop[1].body:getX(), hoop[1].body:getY(), hoop[1].shape:getRadius())
    love.graphics.circle('fill', hoop[2].body:getX(), hoop[2].body:getY(), hoop[2].shape:getRadius())
    love.graphics.polygon('fill', backboard.body:getWorldPoints(backboard.shape:getPoints()))
  end
end

-- Shoot the ball by pressing space
function love.keypressed(key)
  if key == 'space' then
    shotTimer = 0.00
    -- Go from aiming to selecting power
    if shotStep == 'aim' then
      shotStep = 'power'
      love.audio.play(powerSound:clone())
    -- Go from selecting power to shooting the ball
    elseif shotStep == 'power' then
      shotStep = 'shoot'
      love.audio.play(shootSound:clone())
      local speed = 180 * shotPower + 120
      ball.body:setLinearVelocity(speed * math.cos(shotAngle), speed * math.sin(shotAngle))
    -- And then press space again to start aiming again
    elseif shotStep == 'shoot' then
      shotAngle = 0
      shotPower = 0
      shotStep = 'aim'
      love.audio.play(aimSound:clone())
    end
  end
end

-- Play a sound when there's a collision
function onCollide()
  love.audio.play(bounceSound:clone())
end

-- Creates a new physics object that's just a 2D circle
function createCircle(x, y, radius, isStatic)
  -- Create the physics objects
  local body = love.physics.newBody(world, x, y, isStatic and 'static' or 'dynamic')
  local shape = love.physics.newCircleShape(radius)
  local fixture = love.physics.newFixture(body, shape, 1)
  -- Return the circle
  return { body = body, shape = shape, fixture = fixture }
end

-- Creates a new physics object that's just a 2D rectangle
function createRectangle(x, y, width, height, isStatic)
  -- Create the physics objects
  local body = love.physics.newBody(world, x, y, isStatic and 'static' or 'dynamic')
  local shape = love.physics.newRectangleShape(width, height)
  local fixture = love.physics.newFixture(body, shape, 1)
  -- Return the rectangle
  return { body = body, shape = shape, fixture = fixture }
end
