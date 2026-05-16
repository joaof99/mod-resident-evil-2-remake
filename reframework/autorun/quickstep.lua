local utilizouBoost = false
local quandoBoostComecou = 0
local esperandoSoltar = false

local ultimoBoost = 0

local tempoCooldown = 2.0
local velocidadeBoost = 1.55
local duracaoBoost = 0.6

local VALORES_PADRAO = {
    velocidadeBoost = 1.55,
    tempoCooldown = 2.0,
    duracaoBoost = 0.6
}

local gp_singleton = sdk.get_native_singleton("via.hid.Gamepad")
local gp_typedef = sdk.find_type_definition("via.hid.GamePad")

local function isBitSet(bit, nInt)
    if not nInt then
        return false
    end
    return (nInt & (0x1 << bit)) > 0
end

local posX = 100
local posY = 200
local larguraBarra = 150
local alturaBarra = 12

re.on_draw_ui(function()
    if imgui.tree_node("Configurações do Quickstep") then
        local mudouVelocidade, novaVelocidade = imgui.slider_float("Velocidade do Boost", velocidadeBoost, 1.0, 5.0, "%.2f")
        if mudouVelocidade then
            velocidadeBoost = novaVelocidade
        end

        local mudouDuracaoBoost, novaDuracaoBoost = imgui.slider_float("Duração do Boost", duracaoBoost, 0.1, 3.0, "%.2f")
        if mudouDuracaoBoost then
            duracaoBoost = novaDuracaoBoost
        end

        local mudouCooldown, novoCooldown = imgui.slider_float("Tempo de Cooldown", tempoCooldown, 0.1, 10.0, "%.2f")
        if mudouCooldown then
            tempoCooldown = novoCooldown
        end

        imgui.spacing()

        if imgui.button("Resetar valores padrão") then
            resetarValoresPadrao()
        end

        imgui.tree_pop()
    end
end)

local function resetarValoresPadrao()
    velocidadeBoost = VALORES_PADRAO.velocidadeBoost
    duracaoBoost = VALORES_PADRAO.duracaoBoost
    tempoCooldown = VALORES_PADRAO.tempoCooldown
end

re.on_frame(function()
    local agora = os.clock()
    local tempoPassado = agora - ultimoBoost
    local pronto = tempoPassado >= tempoCooldown
    local progresso = math.min(tempoPassado / tempoCooldown, 1.0)

    local draw_list = imgui.get_foreground_draw_list()

    local corFundo = 0xFF444444 -- Cinza escuro
    local corPronto = 0xFF00FF00 -- Verde
    local corRecarga = 0xFF0000FF -- Vermelho

    draw_list:add_rect_filled({ posX, posY }, { posX + larguraBarra, posY + alturaBarra }, corFundo)

    local corAtual = pronto and corPronto or corRecarga
    draw_list:add_rect_filled({ posX, posY }, { posX + (larguraBarra * progresso), posY + alturaBarra }, corAtual)

    local texto = pronto and "FÔLEGO PARA BOOST" or "RECUPERANDO FÔLEGO PARA BOOST"
    draw_list:add_text({ posX, posY - 20 }, corAtual, texto)

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
            if (agora - quandoBoostComecou) >= duracaoBoost then
                local msc = player:call("get_GameObject"):call("getComponent(System.Type)",
                        sdk.find_type_definition("app.ropeway.MotionSpeedController"):get_runtime_type())
                if msc then
                    msc:set_field("<PlaySpeed>k__BackingField", 1.0)
                end
                utilizouBoost = false
                ultimoBoost = agora
            end
        end

        if not apertouRBOuTaMirando and esperandoSoltar then
            esperandoSoltar = false
        end
    end
end)