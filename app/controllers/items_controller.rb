class ItemsController < ApplicationController

  require 'payjp'
  before_action :set_item, only: [:show, :destroy, :edit, :confirm, :pay, :update]
  before_action :set_categories, only: [:index, :show, :search, :new, :create, :edit]

  def index # トップページ、アイテムをカテゴリー別に最新投稿順番に
    @ladies_items = set_category_items('レディース')
    @mens_items = set_category_items('メンズ')
    @kids_items = set_category_items('ベビー・キッズ')
    @cosme_items = set_category_items('コスメ・香水・美容')
  end

  def new
    @item = Item.new
    10.times {@item.images.build}
  end

  def create
    @item = Item.new(params_new)
    if params[:item][:grandchild_category_id].present?
      @item[:category_id] = params[:item][:grandchild_category_id]
    elsif params[:item][:child_category_id].present?
      @item[:category_id] = params[:item][:child_category_id]
    else
      @item[:category_id] = params[:item][:parent_category_id]
    end
    respond_to do |format|
      if @item.save
        # @itemページのpayjpカラムが問題で、出品ページに飛ばすのは現状ではエラー、記述使用の可能性あり
        # format.html { redirect_to @item, notice: 'Item was successfully created.' }
        # rails scaffold item で自動作成されたコントローラ記述をそのまま移植。
        # TODO: 仮置きredirect, 最終形=>newページ内でモーダル表示させる
        UserItem.create(user_id: current_user.id, item_id: @item.id)
        format.html { redirect_to root_path, notice: 'Item was successfully created.' }
        format.json { render :show, status: :created, location: @item }
      else
        # TODO: 最終形=>入力不備label部分に赤字でガイド表示させる
        format.html { render :new }
        format.json { render json: @item.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @items = Item.order(id: 'DESC').limit(4)
    @same_category_items = Item.where(category_id: @item.category_id).where.not(id: @item.id).order(id: 'DESC').limit(6)
  end

  def confirm
    if user_signed_in?
      Payjp.api_key = Rails.application.credentials.payjp[:secret_access_key]
      customer = Payjp::Customer.retrieve(current_user.payjp_id)
      default_card = customer.default_card
      @card = customer.cards.retrieve(default_card)
    else
      redirect_to new_user_session_path
    end
  end

  def edit
  end

  def update
    if @item.update(params_new)
      redirect_to item_path(@item)
    else
      redirect_to edit_item_path
    end
  end

  def search
    @items = Item.where('name LIKE(?)', "%#{params[:keyword]}%").limit(40)
    if @items.count == Item.all.count || params[:keyword].present? == false
      @items = Item.order(id: "DESC").limit(40)
    end
    # 余裕があればkaminariを入れて、limit(40)を外す
  end

  def destroy
    if @item.destroy
      redirect_to root_path
    else
      redirect_to item_path(@item)
    end
  end

  private

  def params_new
    params.require(:item).permit(:name, :condition, :detail, :delivery_method, :delivery_prefecture, :delivery_cost, :delivery_day, :price, images_attributes: [:image, :image_cache, :remove_image])
  end

  def set_item
    @item = Item.find(params[:id])
  end

  def set_category_items(name)
    Item.where(category_id: Category.find_by(name: name).id, status: 1).order(id: "DESC").limit(4)
  end
end
