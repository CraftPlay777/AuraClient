local FORM = "helpclient:menu"
local selected = 1

local cmds = {
    {".speed",   "Cambia tu velocidad de movimiento local.",
        ".speed {bloques por segundo}\n.speed off  ->  vuelve a la velocidad del servidor"},

    {".hit",     "Auto-golpe. Golpea automaticamente la entidad que tengas delante.",
        ".hit {golpes por segundo}\n.hit off  ->  apaga el auto-golpe"},

    {".click",   "Auto-click. Hace N taps por segundo al item seleccionado. Requiere confirmar.",
        ".click {hits/seg} {repeticiones}\n.click ok  ->  confirma y arranca\n.click off  ->  apaga"},

    {".helpclient", "Abre esta ventana de ayuda.",
        ".helpclient"},
}

local function esc(s)
    return minetest.formspec_escape(s)
end

local function get_formspec(sel)
    local items = {}
    for i, c in ipairs(cmds) do
        items[i] = esc(c[1])
    end
    local c = cmds[sel] or cmds[1]

    return table.concat({
        "formspec_version[4]",
        "size[11,8]",
        "label[0.4,0.6;Comandos del cliente disponibles (", #cmds, ")]",
        "textlist[0.4,1;3.6,5.6;cmdlist;", table.concat(items, ","), ";", sel, ";false]",
        "box[4.3,1;6.3,5.6;#00000080]",
        "label[4.6,1.5;Comando: ", esc(c[1]), "]",
        "label[4.6,2.1;Descripcion:]",
        "textarea[4.6,2.4;5.7,1.4;;;", esc(c[2]), "]",
        "label[4.6,3.9;Uso:]",
        "textarea[4.6,4.3;5.7,3.0;;;", esc(c[3]), "]",
        "button_exit[4.3,6.9;2.4,0.8;close;Cerrar]",
    })
end

local function show_menu()
    minetest.show_formspec(FORM, get_formspec(selected))
end

minetest.register_chatcommand("helpclient", {
    description = "Muestra la ayuda de los comandos del cliente",
    func = function(param)
        selected = 1
        show_menu()
        return true
    end,
})

minetest.register_on_formspec_input(function(formname, fields)
    if formname ~= FORM then
        return false
    end
    if fields.cmdlist then
        local ev = minetest.explode_textlist_event(fields.cmdlist)
        if (ev.type == "CHG" or ev.type == "DCL") and cmds[ev.index] then
            selected = ev.index
            show_menu()
        end
    end
    return true
end)