require File.dirname(__FILE__) + '/spec_helper'

class ValidateDatabaseSpec < Spec::ExampleGroup

  describe "A model" do

    it "should" do
      a = It[{}]
      a.valid?
      puts a.errors.full_messages.inspect
      puts a.attributes.inspect
      a.should be_valid
    end

    Types.each do |type|

      Nulls.each do |null|

        ValueValid[type, null].each do |value_typed, valid|

          [ value_typed, (value_typed.is_a?(String) ? nil : value_typed.to_s) ].flatten.each do |value|

            it "#{Might[valid].humanize.downcase} allow #{R[null]} #{type} to be #{value.inspect}" do

              It[C[type,null] => value].should send(*HaveError[valid]).error_on(C[type,null])

            end

          end

        end

      end

    end

  end

end
