local utilizouBoost = false
local quandoBoostComecou = 0
local velocidadeBoost = 1.55
local duracao_boost = 0.6
local esperandoSoltar = false

local tempoCooldown = 2.0 
local ultimoBoost = 0    

local gp_singleton = sdk.get_native_singleton("via.hid.Gamepad")
local gp_typedef = sdk.find_type_definition("via.hid.GamePad")

local function isBitSet(bit, nInt)
    if not nInt then return false end
    return (nInt & (0x1 << bit)) > 0
end

local posX = 100
local posY = 200
local larguraBarra = 150
local alturaBarra = 12

re.on_frame(function()
    local agora = os.clock()
    local tempoPassado = agora - ultimoBoost
    local pronto = tempoPassado >= tempoCooldown
    local progresso = math.min(tempoPassado / tempoCooldown, 1.0)

    local draw_list = imgui.get_foreground_draw_list()
    
    local corFundo = 0xFF444444 -- Cinza escuro
    local corPronto = 0xFF00FF00 -- Verde
    local corRecarga = 0xFF0000FF -- Vermelho

    draw_list:add_rect_filled({posX, posY}, {posX + larguraBarra, posY + alturaBarra}, corFundo)

    local corAtual = pronto and corPronto or corRecarga
    draw_list:add_rect_filled({posX, posY}, {posX + (larguraBarra * progresso), posY + alturaBarra}, corAtual)

    local texto = pronto and "FÔLEGO PARA BOOST" or "RECUPERANDO FÔLEGO PARA BOOST"
    draw_list:add_text({posX, posY - 20}, corAtual, texto)

    local survivorManager = sdk.get_managed_singleton("app.ropeway.SurvivorManager")
    local player = survivorManager and survivorManager:get_field("<Player>k__BackingField")
    
    if player then
        local gamepad = sdk.call_native_func(gp_singleton, gp_typedef, "getMergedDevice", 0)
        local gp_buttons = gamepad and gamepad:get_Button() or 0
        local apertouShift = reframework:is_key_down(0x10)
        local apertouRBOuTaMirando = apertouShift or isBitSet(10, gp_buttons)

        if apertouRBOuTaMirando and not utilizouBoost and not esperandoSoltar and pronto then
            local msc = player:call("get_GameObject"):call("getComponent(System.Type)",
                sdk.find_type_definition("app.ropeway.MotionSpeedController"):get_runtime_type())

            if msc then
                msc:set_field("<PlaySpeed>k__BackingField", velocidadeBoost)
                utilizouBoost = true
                quandoBoostComecou = agora
                esperandoSoltar = true
            end
        end

        if utilizouBoost then
            if (agora - quandoBoostComecou) >= duracao_boost then
                local msc = player:call("get_GameObject"):call("getComponent(System.Type)",
                    sdk.find_type_definition("app.ropeway.MotionSpeedController"):get_runtime_type())
                if msc then msc:set_field("<PlaySpeed>k__BackingField", 1.0) end
                utilizouBoost = false
                ultimoBoost = agora 
            end
        end

        if not apertouRBOuTaMirando and esperandoSoltar then
            esperandoSoltar = false
        end
    end
end)