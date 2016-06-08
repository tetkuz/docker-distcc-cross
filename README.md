# Docker + distcc + cross compiler

distcc + cross compiler を docker コンテナに入れることで、
ホスト環境を汚さず distcc と cross compiler をインストールすることができます。

## 動作確認済み

 wheezy: arm-linux-gnueabihf-gcc-4.6
stretch: arm-linux-gnueabihf-gcc-5

jessie (shiretoko) は誰か作ってください :-)

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
   `distcc` に加え、`ccache` をインストールすることで、より高速にコンパイルすることができます。

2. ccache の設定
    ```sh
    [Armadillo ~]$ echo 'export PATH=/usr/lib/ccache:$PATH' >> ~/.bashrc
    ```
    `/usr/lib/ccache` にパスを通すと、ccache が使えるようになります。

3. ccache のパス確認
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

2. 分散コンパイルしているかを確認
   - distccmon-text を実行
      ```sh
      [Armadillo ~]$ distccmon-text 0.05
      ```
   - 別ターミナルでコンパイル
    ```sh
    [Armadillo ~]$ DISTCC_HOSTS=[PCのIPアドレス]:9000 CCACHE_PREFIX=distcc gcc -c hoge.c
    ```

    distccmon-text のログに PCのIPアドレスが流れたら OK
    ちなみに、`gcc hoge.c` だとリンクまで一気にやるので distcc が付け入る空きがなく
    分散コンパイルしてくれません。
