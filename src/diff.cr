# A diff algorithm implementation.
#
# This implements Wu's `O(NP)` algorighm described by
# ["An O(NP) Sequence Comparision Algorithm" (Wu, 1989)](https://publications.mpi-cbg.de/Wu_1990_6334.pdf).
module Diff
  # Delta is a delta range of two data.
  # We can get the expected data by replacing values in `obtained_range` with values in `expected_range`.
  record Delta,
    obtained_range : Range(Int32, Int32),
    expected_range : Range(Int32, Int32)

  # Computes a diff from *obtained* to *expected*.
  def self.diff(obtained : Indexable, expected : Indexable) : Array(Delta)
    a, b = obtained, expected
    m, n = a.size, b.size

    a, b, m, n = b, a, n, m if swap = n < m

    path = Array(Int32).new m + n + 3, -1
    points = [] of {Int32, Int32, Int32}

    # Computes the edit distance between `a` and `b`.
    offset = m + 1
    d = n - m
    fp = Array.new m + n + 3, -1

    p = 0
    while true
      (-p..d - 1).each { |k| fp[k + offset] = snake a, b, m, n, path, points, k, fp[k - 1 + offset] + 1, fp[k + 1 + offset], offset }
      (d + 1..d + p).reverse_each { |k| fp[k + offset] = snake a, b, m, n, path, points, k, fp[k - 1 + offset] + 1, fp[k + 1 + offset], offset }
      fp[d + offset] = snake a, b, m, n, path, points, d, fp[d - 1 + offset] + 1, fp[d + 1 + offset], offset

      # In this, the actual edit distance is `d + p * 2`,
      # but we discard it because it does not need to construct a patch.
      break if fp[d + offset] == n
      p += 1
    end

    # Constructs a patch (a delta list).
    pxys = [] of {Int32, Int32}
    r = path[d + offset]
    until r == -1
      px, py, r = points[r]
      pxys << {px, py}
    end

    delta_list = [] of Delta
    x = y = x0 = y0 = 0
    pxys.reverse_each do |(px, py)|
      while x < px && py - px < y - x
        x += 1
      end
      while y < py && py - px > y - x
        y += 1
      end

      if x0 != x || y0 != y
        a_range, b_range = x0...x, y0...y
        obtained_range, expected_range = swap ? {b_range, a_range} : {a_range, b_range}
        delta_list << Delta.new(obtained_range, expected_range)
      end

      while x < px && y < py && py - px == y - x # Skip the same part.
        x += 1
        y += 1
      end
      x0, y0 = x, y
    end

    delta_list
  end

  private def self.snake(a, b, m, n, path, points, k, p, pp, offset)
    r = p > pp ? path[k - 1 + offset] : path[k + 1 + offset]

    y = {p, pp}.max
    x = y - k

    while x < m && y < n && a[x] == b[y]
      x += 1
      y += 1
    end

    path[k + offset] = points.size
    points << {x, y, r}

    y
  end

  # Computes a diff from *obtained* to *expected* on lines,
  # and returns the patch as unified diff format.
  def self.unified_diff(obtained : String, expected : String, *, context : Int32 = 3) : String
    obtained = obtained.split('\n')
    expected = expected.split('\n')
    delta_list = diff(obtained, expected)
    String.build { |str| show_unified_diff str, obtained, expected, delta_list, context: context }
  end

  # Shows this patch as the unified diff format (`diff -u`).
  # Note that it omits filename header like `+++ obtained` and `--- expected`.
  def self.show_unified_diff(io : IO, obtained, expected, delta_list, *, context = 3)
    last_index = 0
    delta_list.each_with_index do |delta, index|
      if index > 0 && (delta.obtained_range.begin - delta_list[index - 1].obtained_range.end) > context * 2
        show_chunk io, obtained, expected, delta_list, last_index..index - 1, context
        last_index = index
      end
    end
    show_chunk io, obtained, expected, delta_list, last_index..delta_list.size - 1, context if last_index != delta_list.size
  end

  private def self.show_chunk(io, obtained, expected, delta_list, delta_range, context)
    obtained_begin_index = delta_list[delta_range.begin].obtained_range.begin
    obtained_begin_index = {obtained_begin_index - context, 0}.max
    expected_begin_index = delta_list[delta_range.begin].expected_range.begin
    expected_begin_index = {expected_begin_index - context, 0}.max

    obtained_end_index = delta_list[delta_range.end].obtained_range.end
    obtained_end_index = {obtained_end_index + context, obtained.size}.min
    expected_end_index = delta_list[delta_range.end].expected_range.end
    expected_end_index = {expected_end_index + context, expected.size}.min

    io << "@@ -" << (obtained_begin_index + 1) << "," << (obtained_end_index - obtained_begin_index) <<
      " +" << (expected_begin_index + 1) << "," << (expected_end_index - expected_begin_index) << " @@"
    io.puts

    obtained_last_index = obtained_begin_index
    delta_range.each do |i|
      delta = delta_list[i]
      (obtained_last_index...delta.obtained_range.begin).each do |j|
        io << " " << obtained[j]
        io.puts
      end
      delta.obtained_range.each do |j|
        io << "-" << obtained[j]
        io.puts
      end
      delta.expected_range.each do |j|
        io << "+" << expected[j]
        io.puts
      end
      obtained_last_index = delta.obtained_range.end
    end
    (obtained_last_index...obtained_end_index).each do |j|
      io << " " << obtained[j]
      io.puts
    end
  end
end
