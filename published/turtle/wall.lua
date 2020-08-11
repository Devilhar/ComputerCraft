args = {...}

length = tonumber(args[1])
height = tonumber(args[2])

if type(length) ~= "number"
    or type(height) ~= "number" then
    error("Invalid args, expected length: [number], height: [number]")
    return
end

function SelectNext()
    while turtle.getItemCount() == 0 do
        local slot = turtle.getSelectedSlot() + 1
        
        if slot > 16 then
            return false
        end
        
        turtle.select(slot)
    end
    
    return true
end

turtle.up()
turtle.select(1)

if not SelectNext() then
    error("No material.")
    return
end

for y = 1, height do
    for x = 1, length do
        if turtle.getItemCount() == 0
            and not SelectNext() then
            error("Ran out of material")
            return false
        end
        
        turtle.placeDown()
        
        if x < length then
            turtle.forward()
        end
    end
    
	if y == height then
		break
	end
	
    turtle.turnLeft()
    turtle.turnLeft()
	
	turtle.up()
end

print("All done! C:")

