require 'test'

describe Configur do 
  describe "#new" do 
   	 it "should initialize variable" do 
     		@conf = Configur.new 
		@conf.test.should eql 'test'
     
      
      
	end
  end
end
