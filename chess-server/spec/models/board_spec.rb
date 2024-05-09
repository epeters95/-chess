require 'rails_helper'

RSpec.describe Board, type: :model do
  describe 'creating a board' do

    params = {
      turn: "white",
      status_str: "Ready to test"
    }

    it 'creates a board with expected fields' do
      b = Board.create(params)

      expect(b).to_not eq(nil)
      expect(b.game_id).to eq(params[:game_id])
      expect(b.turn).to eq(params[:turn])
      expect(b.status_str).to eq(params[:status_str])
    end

    it 'init_vars called after creation' do
      b = Board.new(params)

      expect(b).to receive(:init_variables).once
      b.save

      expect(b.move_count).to eq(1)
    end

    it 'save_pieces_to_positions_array called within init_vars after creation' do
      b = Board.new(params)

      expect(b).to receive(:save_pieces_to_positions_array).once
      b.save
      
      expect(b.positions_array).to_not eq(nil)
    end

    it 'generate_legal_moves called after creation' do
      b = Board.new(params)

      expect(b).to receive(:generate_legal_moves).once
      b.save
      
      expect(b.legal_moves).to_not eq(nil)
    end

  end
end
