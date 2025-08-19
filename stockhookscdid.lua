local WEBHOOK_URL = url
local ROLE_MENTION = "<@&1396091288679612549>"
local ROLE_IDS = {
    "<@&1407018830613446736>",
    "<@&1407018988587716608>",
    "<@&1407019061623263352>",
    "<@&1407019116954517554>"
}
local BOX_NAMES = { "Legendary Box", "Epic Box", "Rare Box", "Common Box" }
local EMBED_COLOR = 0xFFFFFF

-- SERVICES
local Players = game:GetService("Players")
local HS = game:GetService("HttpService")
local localPlayer = Players.LocalPlayer
print("a")
-- UTILS
local function getStock(label)
    return tonumber(label.Text:lower():match("x(%d+)")) or 0
end
local function getRefreshTime()
    return localPlayer:WaitForChild("PlayerGui")
           :WaitForChild("Event").Canvas.Main.CanvasGroup.TextLabel.Text
end
local function sendWebhook(payload)
    local ok, err = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HS:JSONEncode(payload)
        })
    end)
    if not ok then warn(err) end
end

-- EVENT SHOP LOOP
task.spawn(function()
    print("8:50")
    local lastHash = ""
    while true do
        local timer = getRefreshTime():lower()
        if timer:find("8m 50s") then
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
                    embeds = { {
                        title = "— Event Shop Stocks",
                        description = desc,
                        color = EMBED_COLOR,
                        footer = { text = "© Aroel", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
                        image = { url = "https://media.discordapp.net/attachments/1160423812907675729/1404041179766591488/Proyek_Baru_163_30DAF8C.png?ex=6899bebf&is=68986d3f&hm=ccbe265eaeac8f760f2d2c0e020aa79bafbdbca2a00323bb9559b1cd6ab21726&=&format=webp&quality=lossless&width=1385&height=778" },
                        fields = { { name = "Stock Changes in:", value = timer } }
                    } },
                    username = "Aroel — Webhook & Logger"
                })
                lastHash = hash
            end
        end
        task.wait(1)
    end
end)

-- DISCONNECT HANDLER
local function webhookDisconnected()
    local cleanUrl = WEBHOOK_URL:gsub("<.->", ""):match("^%s*(.-)%s*$")
    local embed = {
        author = { name = "Aroel — Webhook & Logger", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
        title = "Disconnected from Server",
        color = 0xFFFFFF,
        description = ROLE_MENTION .. "\nClient has been disconnected from server!",
        fields = { { name = "Username", value = localPlayer.Name, inline = false } },
        image = { url = "https://media.discordapp.net/attachments/1160423812907675729/1404041179766591488/Proyek_Baru_163_30DAF8C.png?ex=689c61bf&is=689b103f&hm=93a309a791285029ef7f39b892d5e7be9dc836154b5af4efb8435bcaf704bcd1&=&format=webp&quality=lossless&width=1385&height=778" },
        footer = { text = "Powered by AroelHub", icon_url = "https://yt3.googleusercontent.com/oKQxVI010a-oqeC-sdjYnhMf8DXqyhybw-iDc4HyxKzqKKV3SIRr2wqPGbvnhHrV-Iu3MzrdWg=s1920-c-k-c0x00ffffff-no-rj" },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S") .. ".000Z"
    }
    local ok, resp = pcall(function()
        return request({
            Url = cleanUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HS:JSONEncode({ content = ROLE_MENTION, embeds = { embed } })
        })
    end)
    if ok and resp and resp.StatusCode == 204 then
        print("[Aroel] Disconnect webhook sent @", ROLE_MENTION)
    else
        warn("[Aroel] Webhook Error:", resp and resp.StatusCode or "network error")
    end
end

localPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then webhookDisconnected() end
end)

print("a")
