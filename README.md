# Docker + distcc + cross compiler

distcc + cross compiler を docker コンテナにまとめることで
ホスト環境を汚さず distcc と cross compiler を使うことができます。

distcc は標準で avahi に対応していますが、Dockerfile には
これを含んでいません。そのため、クライアント(Armadillo)側で
`DISTCC_HOSTS` の環境変数を設定する必要があります。

## 動作確認済み

ファイル名        : gcc バージョン
wheezy.Dockerfile : arm-linux-gnueabihf-gcc-4.6
jessie.Dockerfile : arm-linux-gnueabihf-gcc-4.9
stretch.Dockerfile: arm-linux-gnueabihf-gcc-5

## Armadillo と合わせて使うには

ここでは、a800系 (wheezy) を例に解説します。

詳しくは各 help を参照してください。
- `docker  --help`
- `ccache  --help`
- `distcc  --help`
- `distccd --help`

### Step 1: PCの設定

1. [Docker](https://www.docker.com/) のインストール
   - 参考: https://docs.docker.com/linux/step_one/

2. コンテナのビルド
    ```sh
    [PC ~]$ ls wheezy.Dockerfile
    wheezy.Dockerfile
    [PC ~]$ docker build -t wheezy_distcc -f wheezy.Dockerfile .
    ```
3. コンテナの起動
    ```sh
    [PC ~]$ docker run -d -p 9000:3632 wheezy_distcc
    ```
    これで分散コンパイル(distccd + arm-linux-gnueabihf-gcc)の準備は完了です。
    ここでは 9000番ポート を指定していますが好きなポートで問題ありません。
    ポートを分けることで、複数のコンテナ(cross compiler + distcc)を
    立ち上げることができます

### Step 2: Armadillo 上の設定

0. Armadillo 上では Debian を動作させる必要があります。
  - http://armadillo.atmark-techno.com/armadillo-840/downloads

1. distcc, ccache のインストール
    ```sh
    [Armadillo ~]$ sudo apt-get install distcc ccache
    ```
   `distcc` に加え、`ccache` をインストールすることで、2回目以降のコンパイルがより高速になります。

2. ccache の設定
    ```sh
    [Armadillo ~]$ echo 'export PATH=/usr/lib/ccache:$PATH' >> ~/.bashrc
    ```
    `/usr/lib/ccache` にパスを通すと、ccache が使えるようになります。

3. gccのパス(ccacheが有効になっているか)を確認
    ```sh
    [Armadillo ~]$ which gcc
    /usr/lib/ccache/gcc
    ```
    `/usr/lib/ccache/gcc` が表示されればOKです。


     **以上で準備は完了です**

### Step 3: 分散コンパイルを試す

1. コードの準備
    ```sh
    [Armadillo ~]$ echo 'int main() { return 0; }' > hoge.c
    ```

2. 分散コンパイル
    ```sh
    [Armadillo ~]$ DISTCC_HOSTS=[PCのIPアドレス]:9000 CCACHE_PREFIX=distcc gcc -c hoge.c
    ```

- 補足1: 分散コンパイルしているかを確認
   - distccmon-text を実行
      ```sh
      [Armadillo ~]$ distccmon-text 0.05
      ```
   - 別ターミナルでコンパイル
    ```sh
    [Armadillo ~]$ DISTCC_HOSTS=[PCのIPアドレス]:9000 CCACHE_PREFIX=distcc gcc -c hoge.c
    ```

    distccmon-text のログに PCのIPアドレスが流れたら OK
    ちなみに、`gcc hoge.c` だとリンクまで一気にやるので distcc が付け入る隙がなく
    分散コンパイルしてくれません。

- 補足2: Makefile があるときは?
    - 同じように make するだけ
    ```sh
    [Armadillo ~]$ DISTCC_HOSTS=[PCのIPアドレス]:9000 CCACHE_PREFIX=distcc make -j16
    ```
    作業用PCのコア数に合わせて `-j` オプションで並列化させると効果を体験しやすいです。

