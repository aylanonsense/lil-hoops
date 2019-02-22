-- Render constants
local GAME_WIDTH = 200
local GAME_HEIGHT = 200
local RENDER_SCALE = 3
local DRAW_PHYSICS_OBJECTS = false

-- Game constants
local BALL_BOUNCINESS = 0.7
local GRAVITY = 200

-- Game objects
local world
local ball
local hoop
local backboard

-- Images
local ballImage
local hoopImage

-- Initializes the game
function love.load()
  -- Load images
  ballImage = love.graphics.newImage('img/ball.png')
  ballImage:setFilter('nearest', 'nearest')
  hoopImage = love.graphics.newImage('img/hoop.png')
  hoopImage:setFilter('nearest', 'nearest')

  -- Set up the physics world
  love.physics.setMeter(10)
  world = love.physics.newWorld(0, GRAVITY, true)
 
  -- Create the ball
  ball = createCircle(25, 140, 8)
  ball.fixture:setRestitution(BALL_BOUNCINESS)
  ball.hasBeenShot = false

  -- Create the hoop (it's actually just two fixed circles, one for each side of the rung)
  hoop = {
    createCircle(147, 82, 2, true),
    createCircle(171, 82, 2, true)
  }

  -- Create the static backboard
  backboard = createRectangle(178, 65, 5, 50, true)
end

-- Updates the game state
function love.update(dt)
  -- Update the physics simulation
  world:update(dt)

  if not ball.hasBeenShot then
    ball.body:setPosition(25, 140)
    ball.body:setLinearVelocity(0, 0)
  end
end

-- Renders the game
function love.draw()
  -- Scale up the screen
  love.graphics.scale(RENDER_SCALE, RENDER_SCALE)

  -- Clear the screen
  love.graphics.setColor(252 / 255, 147 / 255, 1 / 255)
  love.graphics.rectangle('fill', 0, 0, GAME_WIDTH, GAME_HEIGHT)
  love.graphics.setColor(1, 1, 1)

  -- Draw the ball
  love.graphics.draw(ballImage, ball.body:getX() - 8, ball.body:getY() - 8)

  -- Draw the hoop
  love.graphics.draw(hoopImage, 146, 40)

  -- Draw the physics objects (for debugging)
  if DRAW_PHYSICS_OBJECTS then
    love.graphics.circle('fill', ball.body:getX(), ball.body:getY(), ball.shape:getRadius())
    love.graphics.circle('fill', hoop[1].body:getX(), hoop[1].body:getY(), hoop[1].shape:getRadius())
    love.graphics.circle('fill', hoop[2].body:getX(), hoop[2].body:getY(), hoop[2].shape:getRadius())
    love.graphics.polygon('fill', backboard.body:getWorldPoints(backboard.shape:getPoints()))
  end
end

-- Shoot the ball
function love.keypressed(key)
  if key == 'space' then
    if not ball.hasBeenShot then
      ball.hasBeenShot = true
      ball.body:setLinearVelocity(100, -197)
    end
  end
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
