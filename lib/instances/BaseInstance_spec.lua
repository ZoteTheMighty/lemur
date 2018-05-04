local BaseInstance = import("./BaseInstance")

local Game = import("./Game")
local Folder = import("./Folder")
local typeof = import("../functions/typeof")

describe("instances.BaseInstance", function()
	it("should error when parenting instances to invalid objects", function()
		local new = BaseInstance:new()

		assert.has.errors(function()
			new.Parent = 7
		end)
	end)

	it("should error when setting unknown values", function()
		local new = BaseInstance:new()

		assert.has.errors(function()
			new.frobulations = 6
		end)
	end)

	it("should error when indexing invalid instances", function()
		local instance = BaseInstance:new()

		local function nop()
		end

		assert.has.errors(function()
			nop(instance.neverWillEXIST)
		end)
	end)

	it("should be identified by typeof", function()
		local instance = BaseInstance:new()

		assert.equal(typeof(instance), "Instance")
	end)

	it("should allow the change and read of Name", function()
		local instance = BaseInstance:new()
		assert.equal(instance.Name, "Instance")

		instance.Name = "Foobar"
		assert.equal(instance.Name, "Foobar")
	end)

	it("should not allow the change of ClassName", function()
		local instance = BaseInstance:new()

		assert.has.errors(function()
			instance.ClassName = "Foobar"
		end)
	end)

	describe("Parent", function()
		it("should set to nil", function()
			local parent = BaseInstance:new()

			local child = BaseInstance:new()
			child.Parent = parent
			child.Name = "foo"

			assert.equal(parent:FindFirstChild("foo"), child)

			child.Parent = nil

			assert.equal(parent:FindFirstChild("foo"), nil)
		end)

		it("should set to other instances", function()
			local parent1 = BaseInstance:new()
			local parent2 = BaseInstance:new()

			local child = BaseInstance:new()
			child.Parent = parent1
			child.Name = "foo"

			assert.equal(parent1:FindFirstChild("foo"), child)

			child.Parent = parent2

			assert.equal(parent1:FindFirstChild("foo"), nil)
			assert.equal(child.Parent, parent2)
			assert.equal(parent2:FindFirstChild("foo"), child)
		end)

		-- This may seem like a weird test, but it's for 100% coverage
		it("shouldn't react differently when setting the parent to the existing parent", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			assert.has_no_errors(function()
				child.Parent = parent
			end)
		end)
	end)

	describe("FindFirstChild", function()
		it("should never error on invalid index", function()
			local instance = BaseInstance:new()

			assert.equal(instance:FindFirstChild("NEVER. WILL. EXIST!"), nil)
		end)
	end)

	describe("GetChildren", function()
		it("should return no children for empty instances", function()
			local instance = BaseInstance:new()

			assert.equal(#instance:GetChildren(), 0)
		end)

		it("should yield all children", function()
			local parent = BaseInstance:new()

			local child1 = BaseInstance:new()
			child1.Parent = parent

			local child2 = BaseInstance:new()
			child2.Parent = parent

			assert.equal(#parent:GetChildren(), 2)

			local child1Seen = false
			local child2Seen = false
			for _, child in ipairs(parent:GetChildren()) do
				if child == child1 then
					child1Seen = true
				elseif child == child2 then
					child2Seen = true
				else
					error("Invalid child found")
				end
			end

			assert.equal(child1Seen, true)
			assert.equal(child2Seen, true)
		end)
	end)

	describe("WaitForChild", function()
		it("should work just like FindFirstChild", function()
			local parent = BaseInstance:new()

			local child = BaseInstance:new()
			child.Parent = parent
			child.Name = "foo"

			local result = parent:WaitForChild("foo")
			assert.equal(result, child)

			child.Parent = nil
			result = parent:WaitForChild("foo")
			assert.equal(result, nil)
		end)
	end)

	describe("Destroy", function()
		it("should set the instance's Parent to nil", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			assert.equal(child.Parent, parent)

			child:Destroy()

			assert.equal(child.Parent, nil)
		end)

		it("should set the children's parents to nil", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			parent:Destroy()
			assert.equal(child.Parent, nil)
		end)

		it("should lock the parent property", function()
			local instance = BaseInstance:new()
			local badParent = BaseInstance:new()

			instance:Destroy()

			assert.has.errors(function()
				instance.Parent = badParent
			end)
		end)

		it("should only lock its own instance, and not all of the same type", function()
			local destroyFolder = BaseInstance:new()
			destroyFolder:Destroy()
			assert.equal(destroyFolder.Parent, nil)

			local goodParent = BaseInstance:new()
			local goodFolder = BaseInstance:new()

			assert.has_no.errors(function()
				goodFolder.Parent = goodParent
			end)
		end)
	end)

	describe("IsA", function()
		it("should check classes directly", function()
			local instance = BaseInstance:new()

			assert.equal(instance:IsA("Instance"), true)
		end)
	end)

	describe("GetFullName", function()
		it("should get the full name", function()
			local instance = BaseInstance:new()
			instance.Name = "Test"
			local other = BaseInstance:new()
			other.Name = "Parent"

			instance.Parent = other

			local fullName = instance:GetFullName()
			assert.equal("Parent.Test", fullName)
		end)

		it("should exclude game", function()
			local instance = BaseInstance:new()
			instance.Name = "Test"
			local other = Game:new()
			other.Name = "Parent"

			instance.Parent = other

			local fullName = instance:GetFullName()
			assert.equal("Test", fullName)
		end)

		it("should return the instance name if there is no parent", function()
			local instance = BaseInstance:new()
			instance.Name = "Test"

			local fullName = instance:GetFullName()
			assert.equal("Test", fullName)
		end)
	end)

	describe("tostring", function()
		it("should match the name of the instance", function()
			local instance = BaseInstance:new()
			instance.Name = "foo"

			assert.equal(tostring(instance), "foo")
		end)
	end)

	describe("Changed", function()
		it("should fire Changed", function()
			local instance = BaseInstance:new()

			local changedSpy = spy.new(function() end)
			instance.Changed:Connect(changedSpy)

			instance.Name = "NameChange"
			assert.spy(changedSpy).was.called_with("Name")
		end)
	end)

	describe("GetPropertyChangedSignal", function()
		it("should fire property signals for the right property", function()
			local instance = BaseInstance:new()
			local spy = spy.new(function() end)
			instance:GetPropertyChangedSignal("Name"):Connect(spy)
			instance.Name = "NameChange"
			assert.spy(spy).was.called()
		end)

		it("should not fire property signals for the incorrect property", function()
			local instance = BaseInstance:new()
			local spy = spy.new(function() end)
			instance:GetPropertyChangedSignal("Parent"):Connect(spy)
			instance.Name = "NameChange2"
			assert.spy(spy).was_not_called()
		end)

		it("should error when given an invalid property name", function()
			local instance = BaseInstance:new()
			assert.has.errors(function()
				instance:GetPropertyChangedSignal("CanDestroyTheWorld"):Connect(function() end)
			end)
		end)
	end)

	describe("ClearAllChildren", function()
		it("should clear children", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			parent:ClearAllChildren()
			assert.equal(child.Parent, nil)
		end)
	end)

	describe("FindFirstAncestor", function()
		it("should find ancestors", function()
			local parent = BaseInstance:new()
			parent.Name = "Ancestor"

			local child = BaseInstance:new()
			child.Parent = parent

			assert.equal(child:FindFirstAncestor("Ancestor"), parent)
		end)

		it("should return nil with no matching ancestor", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			assert.equal(child:FindFirstAncestor("Ancestor"), nil)
		end)

		it("should return nil with no ancestor", function()
			local child = BaseInstance:new()

			assert.equal(child:FindFirstAncestor("Ancestor"), nil)
		end)
	end)

	describe("FindFirstAncestorOfClass", function()
		it("should find ancestors", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			assert.equal(child:FindFirstAncestorOfClass("Instance"), parent)
		end)

		it("should return nil with no matching ancestor", function()
			local parent = BaseInstance:new()
			local child = BaseInstance:new()
			child.Parent = parent

			assert.equal(child:FindFirstAncestorOfClass("Ancestor"), nil)
		end)

		it("should return nil with no ancestor", function()
			local child = BaseInstance:new()

			assert.equal(child:FindFirstAncestorOfClass("Instance"), nil)
		end)
	end)

	describe("FindFirstChildOfClass", function()
		it("should find instances", function()
			local parent = BaseInstance:new()
			local childCorrect = BaseInstance:new()
			childCorrect.Parent = parent

			local childIncorrect = Folder:new()
			childIncorrect.Parent = parent

			assert.equal(parent:FindFirstChildOfClass("Instance"), childCorrect)
		end)

		it("should return nil with no matching child", function()
			local parent = BaseInstance:new()

			local childIncorrect = BaseInstance:new()
			childIncorrect.Parent = parent

			assert.equal(parent:FindFirstChildOfClass("Folder"), nil)
		end)

		it("should return nil with no children", function()
			local parent = BaseInstance:new()

			assert.equal(parent:FindFirstChildOfClass("Folder"), nil)
		end)
	end)

	describe("FindFirstChildOfClass", function()
		it("should find instances", function()
			local parent = BaseInstance:new()
			local childCorrect = BaseInstance:new()
			childCorrect.Parent = parent

			local childIncorrect = Folder:new()
			childIncorrect.Parent = parent

			assert.equal(parent:FindFirstChildWhichIsA("Instance"), childCorrect)
		end)

		it("should return nil with no matching child", function()
			local parent = BaseInstance:new()

			local childIncorrect = BaseInstance:new()
			childIncorrect.Parent = parent

			assert.equal(parent:FindFirstChildWhichIsA("Folder"), nil)
		end)

		it("should return nil with no children", function()
			local parent = BaseInstance:new()

			assert.equal(parent:FindFirstChildWhichIsA("Folder"), nil)
		end)
	end)
end)