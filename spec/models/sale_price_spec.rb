require 'spec_helper'

describe Spree::SalePrice do

  it 'can start and end never' do
    sale_price = build(:sale_price)
    sale_price.start

    expect(sale_price).to be_enabled
    expect(sale_price.end_at).to be(nil)
  end

  it 'can start and then end at a specific time' do
    sale_price = build(:sale_price)
    sale_price.start(1.day.from_now)

    expect(sale_price).to be_enabled
    expect(sale_price.end_at).to be_within(1.second).of(1.day.from_now)
  end

  it 'can stop' do
    sale_price = build(:active_sale_price)
    sale_price.stop

    expect(sale_price).not_to be_enabled
    expect(sale_price.end_at).to be_within(1.second).of(Time.now)
  end

  it 'can create a money price ready to display' do
    sale_price = build(:active_sale_price)
    money = sale_price.display_price

    expect(money).to be_a Spree::Money
    expect(money.money.amount.to_f).to be_within(0.1).of(sale_price.calculated_price.to_f)
    expect(money.money.currency).to eq(sale_price.currency)
  end

  context 'touching associated product when destroyed' do
    subject { -> { sale_price.destroy } }
    let!(:product) { sale_price.product }
    let(:sale_price) { Timecop.travel(1.day.ago) { create(:sale_price) } }

    it { is_expected.to change { sale_price.product.reload.updated_at } }

    context 'when associated product has been destroyed' do
      it 'does not touch product' do
        expect(sale_price).to receive(:product).and_return nil

        expect(subject).not_to change { product.reload.updated_at }
      end
    end

    context 'when associated variant has been destroyed' do
      it 'does not touch product' do
        expect(sale_price).to receive(:variant).and_return nil

        expect(subject).not_to change { product.reload.updated_at }
      end
    end

    context 'when associated price has been destroyed' do
      it 'does not touch product' do
        sale_price.price.delete
        sale_price.reload

        expect(subject).not_to change { product.reload.updated_at }
      end
    end
  end
end
