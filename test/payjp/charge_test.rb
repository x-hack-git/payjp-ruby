require File.expand_path('../../test_helper', __FILE__)

module Payjp
  class ChargeTest < Test::Unit::TestCase
    should "charges should be listable" do
      @mock.expects(:get).once.returns(test_response(test_charge_array))
      c = Payjp::Charge.all
      assert c.data.is_a? Array
      c.each do |charge|
        assert charge.is_a?(Payjp::Charge)
      end
    end

    should "charges should be refundable" do
      @mock.expects(:get).never
      @mock.expects(:post).once.returns(test_response({ :id => "ch_test_charge", :refunded => true }))
      c = Payjp::Charge.new("test_charge")
      c.refund
      assert c.refunded
    end

    should "charges should not be deletable" do
      assert_raises NoMethodError do
        @mock.expects(:get).once.returns(test_response(test_charge))
        c = Payjp::Charge.retrieve("test_charge")
        c.delete
      end
    end

    should "charges should be updateable" do
      @mock.expects(:get).once.returns(test_response(test_charge))
      @mock.expects(:post).once.returns(test_response(test_charge))
      c = Payjp::Charge.new("test_charge")
      c.refresh
      c.mnemonic = "New charge description"
      c.save
    end

    should "charges should have Card objects associated with their Card property" do
      @mock.expects(:get).once.returns(test_response(test_charge))
      c = Payjp::Charge.retrieve("test_charge")
      assert c.card.is_a?(Payjp::PayjpObject) && c.card.object == 'card'
    end

    should "execute should return a new, fully executed charge when passed correct `card` parameters" do
      @mock.expects(:post).with do |url, api_key, params|
        url == "#{Payjp.api_base}/v1/charges" && api_key.nil? && CGI.parse(params) == {
          'currency' => ['jpy'], 'amount' => ['100'],
          'card[exp_year]' => ['2012'],
          'card[number]' => ['4242424242424242'],
          'card[exp_month]' => ['11']
        }
      end.once.returns(test_response(test_charge))

      c = Payjp::Charge.create({
        :amount => 100,
        :card => {
          :number => "4242424242424242",
          :exp_month => 11,
          :exp_year => 2012
        },
        :currency => "jpy"
      })
      assert c.paid
    end

    should "execute should return a new, fully executed charge when passed correct `source` parameters" do
      @mock.expects(:post).with do |url, api_key, params|
        url == "#{Payjp.api_base}/v1/charges" && api_key.nil? && CGI.parse(params) == {
          'currency' => ['jpy'], 'amount' => ['100'],
          'source' => ['btcrcv_test_receiver']
        }
      end.once.returns(test_response(test_charge))

      c = Payjp::Charge.create({
        :amount => 100,
        :source => 'btcrcv_test_receiver',
        :currency => "jpy"
      })
      assert c.paid
    end
  end
end
