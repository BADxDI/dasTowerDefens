require daslib/media
// options debugger            // uncomment for debug in VS Code
// require daslib/debug        // uncomment for debug in VS Code

let GAME_SPEED = 1.0
let CELLS_COUNT = 15
let CELLS_COUNT_ALL = CELLS_COUNT * CELLS_COUNT
let MENU_PANEL_WIDTH = 300

let WAVE_COOLDOWN = 5.0
let WAVE_TIMER = 20.0

//enemy
let SRENGE_FOR_WAVE = 0.1
let MIN_ENEMY_IN_WAVE = 5
let HP_COLOR = 0xFF0000

let shared
    tAll = 0x269926
    tRoad = 0xBF8F30
    tGrass = 0x269926
    tRock = 0x3C3C3C
    tIce = 0x4052FF
    tBase = 0xFF7373

    //map config
var
    map_config: array<uint>
    way_points_pos_x, way_points_pos_y: array<int>

struct Tower
    landType: int
    damage: float
    radius: int
    cooldown: float
    cooldownEnd: float = 0.0
    level: int = 1
    color: uint
    posX: int
    posY: int
    enemyId: int
    isSelected: bool = false

struct TowerLevel
    damage: float
    radius: int
    cooldown: float
    gold: int
    color: uint

struct Bullet
    enemyId: int
    damage: float
    speed = 10.0 * GAME_SPEED
    color = 0x000000
    posX: int
    posY: int
    needDelete: bool = false

struct Enemy
    id: int
    hp: float
    maxHp: float
    speed: float
    damage: float
    curWaypoint: int = 1
    gold: int
    posX: int
    posY: int
    color: uint
    needDelete: bool = false

struct EnemyType
    maxHp: float
    speed: float
    damage: float
    gold: int
    color: uint

var
    enemyTypes = [[auto[]
        [[EnemyType
            maxHp = 25.0,
            speed = 1.5 * GAME_SPEED,
            damage = 2.0,
            gold = 20,
            color = 0x4671D5
        ]];
        [[EnemyType
            maxHp = 15.0,
            speed = 2.5 * GAME_SPEED,
            damage = 1.0,
            gold = 25,
            color = 0x216278
        ]];
        [[EnemyType
            maxHp = 50.0,
            speed = 1.0 * GAME_SPEED,
            damage = 5.0,
            gold = 30,
            color = 0x72217D
        ]]
    ]]

var
    cells_size: int
    enemy_size: int
    tower_size: int
    base_pos_x: int
    base_pos_y: int
    base_hp: float
    cur_wave: int
    cur_gold: int
    time_to_create_new_wave: float
    time_to_create_new_enemy: float
    frequency_create_of_enemy: float
    not_created_enemys_count: int
    game_over: bool
    menu_pos_x: int
    enemy_id_inc: int = 0
    isInEditMod: bool

    towerLevels: array<TowerLevel>
    enemies: array<Enemy>
    towers: array<Tower>
    bullets: array<Bullet>

var
    seed: int4

def load_map_config
    for c in [[auto[]
        tAll; tRoad; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tRoad; tRoad; tRoad; tRoad; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tAll; tAll; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tRoad; tRoad; tRoad; tRoad; tRoad; tAll; tAll; tAll; tAll; tRoad; tAll; tAll; tAll; tAll;
        tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tRoad; tRoad; tRoad; tRoad; tBase;
        tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll; tAll
    ]]
        push(map_config, c)
    let index = find_index_if(map_config) <| $(c)
        return c == tBase
    if index >= 0
        base_pos_x = (index - (index / CELLS_COUNT)*CELLS_COUNT)*cells_size
        base_pos_y = index / CELLS_COUNT*cells_size
    base_pos_x
    for p in [[auto[] cells_size + cells_size/2; cells_size + cells_size/2;
        5*cells_size + cells_size/2; 5*cells_size + cells_size/2;
        10*cells_size + cells_size/2; 10*cells_size + cells_size/2; 14*cells_size + cells_size/2
    ]]
        push(way_points_pos_x, p)
    for p in [[auto[] -cells_size; 12*cells_size + cells_size/2;
        12*cells_size + cells_size/2; 3*cells_size + cells_size/2;
        3*cells_size + cells_size/2; 13*cells_size + cells_size/2; 13*cells_size + cells_size/2
    ]]
        push(way_points_pos_y, p)

def draw_map
    for i in range(length(map_config))
        fill_rect((i - (i / CELLS_COUNT)*CELLS_COUNT)*cells_size, i / CELLS_COUNT*cells_size, cells_size, cells_size, map_config[i])

def init_tower_lvl
    for t in [[auto[]
        [[TowerLevel
            damage = 10.0,
            radius = 3*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 150,
            color = 0xFFBBCC
        ]];
        [[TowerLevel
            damage = 15.0,
            radius = 3*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 50,
            color = 0xFFADC1
        ]];
        [[TowerLevel
            damage = 20.0,
            radius = 3*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 100,
            color = 0xFF9FB7
        ]];
        [[TowerLevel
            damage = 30.0,
            radius = 4*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 150,
            color = 0xFF92AD
        ]];
        [[TowerLevel
            damage = 45.0,
            radius = 4*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 200,
            color = 0xFF84a3
        ]];
        [[TowerLevel
            damage = 60.0,
            radius = 5*cells_size,
            cooldown = 2.0 / GAME_SPEED,
            gold = 250,
            color = 0xFF7799
        ]]
    ]]
        push(towerLevels, t)

def get_new_pos(var curPos, pointPos: int; speed, dt: float)   //FIX ME: need correct recalc pos
    var newPos: int
    if (curPos < pointPos)
        newPos = clamp(curPos+int(speed*dt), curPos, pointPos)
    else
        newPos = clamp(curPos-int(speed*dt), pointPos, curPos)
    return newPos

def create_tower(posX, posY: int)
    var t = Tower()
    var tLevel: TowerLevel = towerLevels[0]
    t.posX = posX
    t.posY = posY
    t.damage = tLevel.damage
    t.radius = tLevel.radius
    t.cooldown = tLevel.cooldown
    t.color = tLevel.color
    t.enemyId = -1
    push(towers, t)

def upgrade_tower(index: int)
    if towers[index].level >= length(towerLevels)
        return
    var tLevel: TowerLevel = towerLevels[towers[index].level]
    if tLevel.gold > cur_gold
        return
    towers[index].damage = tLevel.damage
    towers[index].radius = tLevel.radius
    towers[index].cooldown = tLevel.cooldown
    towers[index].color = tLevel.color
    towers[index].level++
    cur_gold-=tLevel.gold

def fire_to_enemy(var t: Tower; e: Enemy; fireTime: float)
    var b = Bullet()
    b.posX = get_new_pos(t.posX, e.posX, b.speed, fireTime)
    b.posY = get_new_pos(t.posY, e.posY, b.speed, fireTime)
    b.damage = t.damage
    b.enemyId = e.id
    b.speed = b.speed * float(cells_size)
    push(bullets, b)
    t.enemyId = e.id
    t.cooldownEnd = t.cooldown - fireTime
    return

def canFireToEnemy(var t: Tower; e: Enemy)
    return abs(t.posX - e.posX) <= t.radius && abs(t.posY - e.posY) <= t.radius

def tryFire(var t: Tower; dt: float)
    var fireTime = 0.0
    if (t.cooldownEnd > 0.0)
        t.cooldownEnd -= dt
    if (t.cooldownEnd > 0.0)
        return
    var index = find_index_if(enemies) <| $(e)
        return t.enemyId == e.id && canFireToEnemy(t, e)
    if index < 0
        index = find_index_if(enemies) <| $(e)
            return canFireToEnemy(t, e)
    if index >= 0
        fire_to_enemy(t, enemies[index], abs(t.cooldownEnd))

def update_towers(var dt: float)
    for t in towers
        tryFire(t, dt)

def tower_render
    for t in towers
        fill_circle(t.posX, t.posY, tower_size/2, t.color)
        if t.isSelected
            circle(t.posX, t.posY, t.radius, t.color)
            if t.level < length(towerLevels)
                fill_rect(t.posX-cells_size/2, t.posY+cells_size/2-cells_size/3, cells_size, cells_size/4, 0xFFFFFF)
                set_font_size(10)
                text_out(t.posX-cells_size/2+2, t.posY+cells_size/2-cells_size/3, "Upg:{towerLevels[t.level].gold}", 0x000000)

def remove_bullet
    let bulletsCount = length(bullets)
    for i in range(bulletsCount)
        var b = bullets[abs(bulletsCount-i-1)]
        if b.needDelete
            erase(bullets, abs(bulletsCount-i-1))

def update_bullets(dt: float)
    for b in bullets
        var index = find_index_if(enemies) <| $(e)
            return e.id == b.enemyId && !e.needDelete
        if index < 0
            b.needDelete = true
            continue
        var e: Enemy = enemies[index]
        b.posX = get_new_pos(b.posX, enemies[index].posX, b.speed, dt)
        b.posY = get_new_pos(b.posY, enemies[index].posY, b.speed, dt)
        if b.posX == enemies[index].posX && b.posY == e.posY
            b.needDelete = true
            enemies[index].hp -= b.damage
            if enemies[index].hp <= 0.0
                enemies[index].needDelete = true
                cur_gold += enemies[index].gold
    remove_bullet()

def bullet_render
    for b in bullets
        if !b.needDelete
            fill_circle(b.posX, b.posY, 3, b.color)

def calculateAtr(defValue:float)
    return defValue + defValue * float(cur_wave) * SRENGE_FOR_WAVE

def create_enemy(eType: int)
    var e = Enemy()
    var eT: EnemyType = enemyTypes[eType]
    e.id = enemy_id_inc
    e.maxHp = calculateAtr(eT.maxHp)
    e.hp = e.maxHp
    e.speed = calculateAtr(eT.speed * float(cells_size))
    e.damage = calculateAtr(eT.damage)
    e.gold = int(calculateAtr(float(eT.gold)))
    e.posX = way_points_pos_x[0]
    e.posY = way_points_pos_y[0]
    e.color = eT.color
    push(enemies, e)
    not_created_enemys_count--
    enemy_id_inc++

def update_enemy(var e: Enemy; dt: float)
    var pointX, pointY: int
    pointX = way_points_pos_x[e.curWaypoint]
    pointY = way_points_pos_y[e.curWaypoint]
    e.posX = get_new_pos(e.posX, pointX, e.speed, dt)
    e.posY = get_new_pos(e.posY, pointY, e.speed, dt)
    if e.posX == pointX && e.posY == pointY
        e.curWaypoint++
    if e.curWaypoint >= length(way_points_pos_x)
        e.needDelete = true
        base_hp-=e.damage

def remove_killed_enemy
    let enemiesCount = length(enemies)
    for i in range(enemiesCount)
        var e = enemies[abs(enemiesCount-i-1)]
        if e.needDelete
            erase(enemies, abs(enemiesCount-i-1))

def update_wave(var dt: float)
    time_to_create_new_wave-=dt
    if time_to_create_new_wave <= 0.0
        not_created_enemys_count = int(calculateAtr(float(MIN_ENEMY_IN_WAVE)))
        frequency_create_of_enemy = WAVE_TIMER / float(not_created_enemys_count-1)
        time_to_create_new_enemy = 0.0
        time_to_create_new_wave = WAVE_TIMER + WAVE_COOLDOWN
        cur_wave++

    time_to_create_new_enemy-=dt
    if not_created_enemys_count > 0 && time_to_create_new_enemy < 0.0
        var rndEtype = random_int(seed) % length(enemyTypes)
        create_enemy(rndEtype)
        time_to_create_new_enemy = frequency_create_of_enemy
    for e in enemies
        if !e.needDelete
            update_enemy(e, dt)
    remove_killed_enemy()

def enemy_render
    for e in enemies
        if (e.needDelete)
            continue
        var posX = e.posX-enemy_size/2
        var posY = e.posY-enemy_size/2
        fill_rect(posX, posY, enemy_size, enemy_size, e.color)
        fill_rect(posX, posY, enemy_size, enemy_size/5, 0x000000)
        fill_rect(posX, posY, int(e.hp*float(enemy_size)/e.maxHp), enemy_size/5, HP_COLOR)

def update_base
    if (base_hp <= 0.0)
        game_over = true

def base_render
    set_font_size(25)
    text_out(base_pos_x, base_pos_y, "{max(0, int(base_hp))}", 0xF0F0F0)

def is_on_obj(x, y, objX, objY, sizeX, sizeY: int)
    return x >= objX && (x <= (objX + sizeX)) && y >= objY && (y <= (objY + sizeY))

def is_position_on_board(x, y: int)
    return is_on_obj(x, y, 0, 0, cells_size * CELLS_COUNT, cells_size * CELLS_COUNT)

def draw_edit_mod
    if !isInEditMod
        return
    let mouse = get_mouse_position()
    let x = int(mouse.x)
    let y = int(mouse.y)
    if !is_position_on_board(x, y)
        return
    fill_circle(x, y, tower_size/2, towerLevels[0].color)
    circle(x, y, towerLevels[0].radius, towerLevels[0].color)

def draw_restart_menu
    enable_alpha_blend()
    fill_rect(0, 0, get_screen_width(), get_screen_height(), 0x70000000)
    disable_alpha_blend()
    set_font_size(cells_size)
    text_out(get_screen_width()/3, get_screen_height()/3, "GAME OVER", 0xF0F0F0)
    set_font_size(cells_size/2)
    text_out(get_screen_width()/3 + cells_size/4, get_screen_height()/3 + 2*cells_size, "Click to restart", 0xF0F0F0)

def draw_menu
    set_font_size(cells_size/2)
    text_out(menu_pos_x, cells_size/4, "Wave: {cur_wave}", 0xF0F0F0)
    text_out(menu_pos_x, cells_size/2+cells_size/4, "Next wave: {int(time_to_create_new_wave)}", 0xF0F0F0)
    text_out(menu_pos_x, cells_size + cells_size/2, "Gold: {cur_gold}", 0xFFFF00)
    text_out(menu_pos_x, 3*cells_size, "Towers", 0xF0F0F0)
    rect(menu_pos_x, 4*cells_size, cells_size, cells_size, 0xF0F0F0)
    fill_circle(menu_pos_x + cells_size/2, 4*cells_size + cells_size/2, tower_size/2, towerLevels[0].color)
    set_font_size(cells_size/4)
    text_out(menu_pos_x, 4*cells_size+cells_size, "Cost:{towerLevels[0].gold}", 0xF0F0F0)
    set_font_size(cells_size/2)
    rect(menu_pos_x, cells_size*CELLS_COUNT-cells_size - cells_size/2, MENU_PANEL_WIDTH-cells_size/2, cells_size+cells_size/2, 0xF0F0F0)
    text_out(menu_pos_x + cells_size, cells_size*CELLS_COUNT-cells_size, "Reset Game", 0xF0F0F0)

def get_tower_index_by_pos(x, y: int)
    var index = find_index_if(towers) <| $(t)
        return (t.posX == x/cells_size*cells_size + cells_size/2) && (t.posY == y/cells_size*cells_size + cells_size/2)
    return index

def can_place_on_cell(x, y: int)
    let cellX = x/cells_size
    let cellY = y/cells_size
    let mapCellIdx = cellY*CELLS_COUNT + cellX
    if (mapCellIdx < 0) || (mapCellIdx > (length(map_config)-1))
        return false

    if map_config[mapCellIdx] != tAll
        return false

    return get_tower_index_by_pos(x, y) < 0

def try_place_tower(x, y: int)
    if !isInEditMod || towerLevels[0].gold > cur_gold
        return
    if !can_place_on_cell(x, y)
        return
    create_tower(x/cells_size*cells_size + cells_size/2, y/cells_size*cells_size + cells_size/2)
    cur_gold -= towerLevels[0].gold

def select_tower(x, y, index: int)
    var t = towers[index]
    if (t.isSelected && t.level < length(towerLevels) && is_on_obj(x, y, t.posX-cells_size/2, t.posY+cells_size/2-cells_size/4, cells_size, cells_size/3))
        upgrade_tower(index)
        return
    towers[index].isSelected = !towers[index].isSelected

def is_tower_button_clicked(x, y: int)
    return is_on_obj(x, y, menu_pos_x, 4*cells_size, cells_size, cells_size)

def is_reset_button_clicked(x, y: int)
    return is_on_obj(x, y, menu_pos_x, cells_size*CELLS_COUNT-cells_size-cells_size/4, MENU_PANEL_WIDTH-cells_size/2, cells_size+cells_size/4)

def on_mouse_click
    let mouse = get_mouse_position()
    let x = int(mouse.x)
    let y = int(mouse.y)
    if is_position_on_board(x, y)
        let index = get_tower_index_by_pos(x, y)
        if index >= 0
            isInEditMod = false
            select_tower(x, y, index)
            return

        try_place_tower(x, y)
        return
    if is_tower_button_clicked(x, y)
        isInEditMod = !isInEditMod
        return

    if is_reset_button_clicked(x, y)
        reset_game()

def reset_game
    game_over = false
    base_hp = 100.0
    cur_wave = 0
    cur_gold = 300
    time_to_create_new_wave = 5.0
    not_created_enemys_count = 0
    enemy_id_inc = 0
    isInEditMod = false
    clear(enemies)
    clear(towers)
    clear(bullets)
  //  create_tower(2*cells_size + cells_size/2, 11*cells_size+cells_size/2)

def init_screen_and_cell_size
    let scrHeight = get_screen_height()
    set_resolution(scrHeight + MENU_PANEL_WIDTH, scrHeight)
    cells_size = scrHeight / CELLS_COUNT
    enemy_size = int(0.7*float(cells_size))
    tower_size = int(0.7*float(cells_size))
    menu_pos_x = cells_size*CELLS_COUNT + cells_size/4
    load_map_config()

// 'initialize' runs once when game starts and every hot-reload
[export]
def initialize
    set_window_title("Tower Defense")
    init_screen_and_cell_size()
    randomize_seed(seed)
    init_tower_lvl()
    reset_game()
    return

// this function is called to update game data,
// dt - time elapsed since the previous update (in seconds)
[export]
def act(dt: float)
    if get_key(VK_ESCAPE)
        schedule_quit_game()

    if game_over && get_mouse_button_up(MB_LEFT)
        reset_game()

    if game_over
        return

    if get_mouse_button_up(MB_LEFT)
        on_mouse_click()

    update_wave(dt)
    update_bullets(dt)
    update_towers(dt)
    update_base()
    return

// this function will be called every frame after 'act',
// you can draw anything in this function
[export]
def draw
    draw_map()
    tower_render()
    enemy_render()
    bullet_render()
    base_render()
    draw_menu()
    if (game_over)
        draw_restart_menu()
    draw_edit_mod()
    return
