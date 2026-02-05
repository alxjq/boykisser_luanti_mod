local modname = "mod1"

-- BoyKisser entity
minetest.register_entity("mod1:boykisser", {
    initial_properties = {
        physical = false,
        collide_with_objects = false,
        pointable = true,
        visual = "sprite",
        textures = {"boykisser.png"},
        visual_size = {x = 1.2, y = 1.8},
        nametag = "",
        static_save = false,
    },

    owner_name = nil,
    stay_mode = false,
    stay_pos = nil,

    on_activate = function(self)
        self.object:set_nametag_attributes({ text = "BoyKisser", color = "#ff77aa" })
    end,

    on_step = function(self, dtime)
        if not self.owner_name then return end
        local player = minetest.get_player_by_name(self.owner_name)
        if not player then
            self.object:remove()
            mod1.boykisser_obj = nil
            return
        end

        local pos = self.object:get_pos()

        if self.stay_mode and self.stay_pos then
            self.object:set_pos(self.stay_pos)
        else
            local target = vector.add(player:get_pos(), {x=1, y=0, z=1})
            self.object:set_pos(vector.add(pos, vector.multiply(vector.subtract(target, pos), 0.12)))
        end

        local dir = vector.direction(pos, player:get_pos())
        local yaw = math.atan2(dir.z, dir.x) + math.pi/2
        self.object:set_yaw(yaw)
    end,
})

-- /boykisser command
minetest.register_chatcommand("boykisser", {
    description = "Summon BoyKisser",
    func = function(name)
        local player = minetest.get_player_by_name(name)
        if not player then return end

        if mod1.boykisser_obj then
            mod1.boykisser_obj:remove()
            mod1.boykisser_obj = nil
        end

        local pos = vector.add(player:get_pos(), {x=1, y=0, z=1})
        local obj = minetest.add_entity(pos, "mod1:boykisser")
        if not obj then return end

        local ent = obj:get_luaentity()
        ent.owner_name = name
        mod1.boykisser_obj = obj

        minetest.chat_send_player(name, "😼 BoyKisser is now following you!")
    end
})

-- /stay command
minetest.register_chatcommand("stay", {
    description = "Make BoyKisser stay or follow again",
    func = function(name)
        local obj = mod1.boykisser_obj
        if not obj then
            minetest.chat_send_player(name, "⚠️ BoyKisser has not been spawned!")
            return
        end
        local ent = obj:get_luaentity()

        if ent.stay_mode then
            ent.stay_mode = false
            minetest.chat_send_player(name, "😼 BoyKisser is now following you again!")
        else
            ent.stay_mode = true
            ent.stay_pos = vector.new(obj:get_pos())
            minetest.chat_send_player(name, "😼 BoyKisser is staying in place!")
        end
    end
})

-- Remove NPC when player leaves
minetest.register_on_leaveplayer(function()
    if mod1.boykisser_obj then
        mod1.boykisser_obj:remove()
        mod1.boykisser_obj = nil
    end
end)
