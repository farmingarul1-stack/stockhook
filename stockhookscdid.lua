-- CONFIG
local WEBHOOK_URL = url
local ROLE_MENTION   = "<@&1396091288679612549>"
local ROLE_IDS       = {
    "<@&1407018830613446736>",
    "<@&1407018988587716608>",
    "<@&1407019061623263352>",
    "<@&1407019116954517554>"
}
local BOX_NAMES      = { "Legendary Box", "Epic Box", "Rare Box", "Common Box" }
local EMBED_COLOR    = 0xFFFFFF

-- SERVICES
local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local HS           = game:GetService("HttpService")
local localPlayer  = Players.LocalPlayer

-- UTILS
local function sendWebhook(payload)
    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HS:JSONEncode(payload)
        })
    end)
end

local function getStock(label)
    return tonumber(label.Text:lower():match("x(%d+)")) or 0
end

local function parseTimer(raw)
    local m, s = raw:lower():match("(%d+)m%s+(%d+)s")
    if m and s then return tonumber(m)*60 + tonumber(s) end
end

local function humanize(sec)
    if sec < 0 then return string.format("%d minute%s ago", -sec//60, -sec//60==1 and "" or "s") end
    return string.format("in %d minute%s", sec//60, sec//60==1 and "" or "s")
end

-- MAIN LOOP
local lastHash = ""
local lastSentAt = 0
local REFRESH_PERIOD = 600 -- 10 menit detik

task.spawn(function()
    while true do
        local timerTxt = localPlayer:WaitForChild("PlayerGui")
                         :WaitForChild("Event").Canvas.Main.CanvasGroup.TextLabel.Text
        local remaining = parseTimer(timerTxt) or 0
        -- trigger pada 600, 590, 570, 550, 540, 530, 520 detik
        local hit = (remaining <= 600 and remaining >= 520)
        if hit and (os.time() - lastSentAt) >= 30 then -- 30 detik antispam
            local canvas = localPlayer.PlayerGui.Event.Canvas.Main.CanvasGroup.ScrollingFrame
            local labels = {
                canvas.Legendary.Main.Stock,
                canvas.Epic.Main.Stock,
                canvas.Rare.Main.Stock,
                canvas.Common.Main.Stock
            }
            local desc, mentions = "", ""
            for i, lbl in ipairs(labels) do
                local stock = getStock(lbl)
                if stock >= 1 then
                    desc = desc .. BOX_NAMES[i] .. " **x" .. stock .. "**\n"
                    mentions = mentions .. ROLE_IDS[i] .. " "
                end
            end
            local hash = desc
            if hash ~= "" and hash ~= lastHash then
                sendWebhook({
                    content = mentions,
                    embeds = {{
                        title  = "— Event Shop Stocks",
                        description = desc,
                        color  = EMBED_COLOR,
                        footer = { text = "© Aroel", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
                        image  = { url = "https://media.discordapp.net/attachments/1160423812907675729/1404041179766591488/Proyek_Baru_163_30DAF8C.png?ex=6899bebf&is=68986d3f&hm=ccbe265eaeac8f760f2d2c0e020aa79bafbdbca2a00323bb9559b1cd6ab21726&=&format=webp&quality=lossless&width=1385&height=778" },
                        fields = { { name = "Next refresh", value = humanize(remaining) } }
                    }},
                    username = "Aroel — Webhook & Logger"
                })
                lastHash = hash
                lastSentAt = os.time()
            end
        end
        task.wait(1)
    end
end)

-- DISCONNECT HANDLER
local function webhookDisconnected()
    local cleanUrl = WEBHOOK_URL:gsub("<.->", ""):match("^%s*(.-)%s*$")
    sendWebhook({
        content = ROLE_MENTION,
        embeds = {{
            author = { name = "Aroel — Webhook & Logger", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
            title = "Disconnected from Server",
            color = 0xFFFFFF,
            description = ROLE_MENTION .. "\nClient has been disconnected from server!",
            fields = { { name = "Username", value = localPlayer.Name, inline = false } },
            image = { url = "https://media.discordapp.net/attachments/1160423812907675729/1404041179766591488/Proyek_Baru_163_30DAF8C.png?ex=689c61bf&is=689b103f&hm=93a309a791285029ef7f39b892d5e7be9dc836154b5af4efb8435bcaf704bcd1&=&format=webp&quality=lossless&width=1385&height=778" },
            footer = { text = "Powered by AroelHub", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. ".000Z"
        }}
    })
end

localPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then webhookDisconnected() end
end)
