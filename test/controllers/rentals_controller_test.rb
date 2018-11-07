require "test_helper"

describe RentalsController do
  let(:rental_params) {
                      {
                        customer_id: customers(:one).id,
                        movie_id: movies(:one).id
                      }
                    }

  describe "checkout" do
    it "checkout path is a working route and returns JSON" do
      post checkout_path params: rental_params
      expect(response.header['Content-Type']).must_include 'json'
      must_respond_with :success
    end

    it "checkout works with valid data" do
      expect {
          post checkout_path, params: rental_params
        }.must_change "Rental.count", 1

      body = JSON.parse(response.body)
      expect(body).must_be_kind_of Hash
      expect(body).must_include "id"

      rental = Rental.find_by(id: body["id"].to_i)

      expect(rental.customer_id).must_equal rental_params[:customer_id]
      expect(rental.movie_id).must_equal rental_params[:movie_id]
      expect(rental.active).must_equal true
      expect(rental.checkout_date).must_equal Date.today
      expect(rental.due_date).must_equal Date.today + 7
      must_respond_with :success
    end

    it "checkout does not work with invalid data" do

      rental_params[:customer_id] = nil

      expect {
            post checkout_path, params: rental_params
          }.wont_change "Rental.count"

      body = JSON.parse(response.body)

      expect(body).must_be_kind_of Hash
      expect(body["errors"]).must_include "customer"
      must_respond_with :bad_request
    end
  end

  describe "checkin" do

    it "checkin path is a working route and returns JSON" do
      post checkin_path params: rental_params
      expect(response.header['Content-Type']).must_include 'json'
      must_respond_with :success
    end

    it "checkin works with valid data" do
      # undefined active
      expect {
          post checkin_path, params: rental_params
        }.wont_change "Rental.count"

      body = JSON.parse(response.body)
      expect(body).must_include "id"
    end

    it "checkin does not work with invalid data" do
      rental_params[:customer_id] = nil

      expect {
            post checkin_path params: rental_params
          }.wont_change "Rental.count"

      body = JSON.parse(response.body)

      expect(body).must_be_kind_of Hash
      expect(body["errors"]).must_include "rental"
      must_respond_with :bad_request
    end
  end

  describe "overdue" do
    it 'renders json' do
      get overdue_path
      expect(response.header['Content-Type']).must_include 'json'
      must_respond_with :success
    end

    it "returns an Array" do
      get overdue_path
      body = JSON.parse(response.body)
      expect(body).must_be_kind_of Array
    end

    it "returns all of the overdue rentals" do
      get overdue_path
      body = JSON.parse(response.body)
      expect(body.length).must_equal Rental.where(["active = ? and due_date < ?", true, Date.today]).count
    end

    it "returns overdues with exactly the required keys" do
      overdue_keys = %w(customer movie rental)
      customer_keys = %w(id name postal_code)
      rental_keys = %w(checkout_date due_date)
      movie_keys = %w(id title)

      get overdue_path

      body = JSON.parse(response.body)

      body.each do |overdue|
        expect(overdue.keys.sort).must_equal overdue_keys
        expect(overdue.keys.length).must_equal overdue_keys.length

        expect(overdue["customer"].keys.sort).must_equal customer_keys
        expect(overdue["movie"].keys.sort).must_equal movie_keys
        expect(overdue["rental"].keys.sort).must_equal rental_keys

      end
    end

    it "returns a message if there are no overdues" do
      overdues = Rental.where(["active = ? and due_date < ?", true, Date.today])
      overdues.each do |overdue|
        overdue.destroy
      end

      get overdue_path

      body = JSON.parse(response.body)
      expect(body["errors"]).must_include "overdues"

    end

  end

end
