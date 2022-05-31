describe EventTracer::Buffer do
  let(:buffer_size) { 10 }
  let(:flush_interval) { 10 }
  let(:buffer) { described_class.new(buffer_size: buffer_size, flush_interval: flush_interval) }

  describe '#add' do
    let(:item) { 'item' }
    subject { buffer.add(item) }

    context 'when buffer is full' do
      let(:buffer_size) { 0 }

      it 'does not add the item' do
        expect {
          expect(subject).to eq false
        }.not_to change { buffer.size }
      end
    end

    context 'when there are items which stay for 10s already' do
      let(:flush_interval) { 0 }

      before { buffer.add('other_item') }

      it 'does not add the item' do
        expect {
          expect(subject).to eq false
        }.not_to change { buffer.size }
      end
    end

    context 'when buffer is available and no long-staying item' do
      it 'adds item to buffer' do
        expect {
          expect(subject).to eq true
        }.to change { buffer.size }.by(1)
      end
    end

    context 'when multiple instances are called' do
      let(:count) { 3 }

      it 'does not affect buffer in other instances' do
        buffers = count.times.map { described_class.new }

        count.times do |i|
          buffers[i].add(i)
          expect(buffers[i].size).to eq 1
        end
      end
    end

    context 'when an instance is called in multiple threads' do
      it 'works properly' do
        buffer = described_class.new(buffer_size: 3, flush_interval: 3)

        threads = 10.times.map do |i|
          Thread.new {
            10.times do
              buffer.flush unless buffer.add(i)
            end
          }
        end

        threads.each(&:join)
      end
    end
  end

  describe '#flush' do
    before do
      buffer.add('item_1')
      buffer.add('item_2')
    end

    it 'clears all items in buffer' do
      expect {
        expect(buffer.flush).to eq ['item_1', 'item_2']
      }.to change { buffer.size }.to(0)
    end
  end
end
