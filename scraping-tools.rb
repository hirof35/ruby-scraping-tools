require 'tk'
require 'nokogiri'
require 'open-uri'

class TkScraperApp
  def initialize
    # メインウィンドウの作成
    @root = TkRoot.new do
      title "ニュース収集ツール (Tk安定版)"
      geometry "800x500"
    end

    # データの管理用配列
    @links_data = []

    setup_ui
  end

  # スクレイピングロジック（実績のある安定コード）
  def fetch_all_links(url)
    return [["URLを入力してください", ""]] if url.empty?

    html = URI.open(url, "User-Agent" => "Mozilla/5.0 (Windows NT 10.0; Win64; x64)") { |f| f.read }
    doc = Nokogiri::HTML.parse(html, nil, 'utf-8')

    data = []
    doc.css('a').each do |a_tag|
      title = a_tag.text.strip
      link = a_tag.attribute('href')&.value

      next if title.empty? || link.nil? || link.start_with?('#') || link.start_with?('javascript:')

      if link.start_with?('/') && !link.start_with?('//')
        base_uri = URI.parse(url)
        link = "#{base_uri.scheme}://#{base_uri.host}#{link}"
      end
      data << [title, link]
    end
    data
  rescue => e
    [["エラーが発生しました", e.message]]
  end

  # UIの構築
  def setup_ui
    # 上部：入力エリア
    input_frame = TkFrame.new(@root).pack(fill: 'x', padx: 10, pady: 5)
    TkLabel.new(input_frame, text: "対象URL:").pack(side: 'left')
    
    @url_entry = TkEntry.new(input_frame) do
      insert('0', 'https://news.yahoo.co.jp/')
      pack(side: 'left', fill: 'x', expand: true, padx: 5)
    end

    # 中央：ボタンエリア
    btn_frame = TkFrame.new(@root).pack(fill: 'x', padx: 10, pady: 5)
    
    TkButton.new(btn_frame, text: "最新ニュースを抽出", command: proc { perform_scrape }).pack(side: 'left', fill: 'x', expand: true, padx: 2)
    TkButton.new(btn_frame, text: "🌐 選択したニュースを開く", command: proc { open_selected_url }).pack(side: 'left', fill: 'x', expand: true, padx: 2)

    # 下部：リストボックス（スクロールバー付き）
    list_frame = TkFrame.new(@root).pack(fill: 'both', expand: true, padx: 10, pady: 5)
    
    scrollbar = TkScrollbar.new(list_frame)
    # Windowsでカチッと確実に選択できるリストボックスを採用
    @listbox = TkListbox.new(list_frame) do
      selectmode 'browse' # 1行選択モード
      pack(side: 'left', fill: 'both', expand: true)
    end
    
    # リストボックスとスクロールバーの連動設定
    @listbox.yscrollbar(scrollbar)
    scrollbar.pack(side: 'right', fill: 'y')
  end

  # ボタン処理：スクレイピング実行
  def perform_scrape
    url = @url_entry.get.strip
    puts ">>> 抽出開始: #{url}"
    
    @links_data = fetch_all_links(url)
    puts ">>> 抽出件数: #{@links_data.size} 件"

    # リストボックスの表示をクリアして再描画
    @listbox.clear
    @links_data.each do |title, _link|
      @listbox.insert('end', " 【ニュース】 #{title}")
    end
  end

  # ボタン処理：ブラウザ起動
  def open_selected_url
    # 選択されている行番号を取得
    selections = @listbox.curselection
    if selections.empty?
      puts ">>> ニュースが選択されていません"
      return
    end

    index = selections.first
    selected_row = @links_data[index]

    if selected_row
      url_to_open = selected_row[1]
      if url_to_open && url_to_open.start_with?('http')
        puts ">>> Tkセーフティ経由で起動: #{url_to_open}"
        
        # WindowsのOSに安全にプロセスを委託する標準命令
        system("start", "", url_to_open)
      end
    end
  end

  # アプリケーションの開始
  def run
    Tk.mainloop
  end
end

# 起動
TkScraperApp.new.run
