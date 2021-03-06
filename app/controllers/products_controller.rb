class ProductsController < ApplicationController

  skip_before_action :current_merchant, except: [:new, :create, :edit, :update, :retire], raise: false
  before_action :require_login, except: [:add_to_cart, :index, :show]

  def new 
    @product = Product.new
  end

  def create 
    @product = Product.new(product_params)
    @product.merchant_id = session[:merchant_id] 

    if @product.save 
      flash[:status] = :success
      flash[:result_text] = "Successfully created #{@product.title}"
      redirect_to product_path(@product.id)
      return
    else
      flash.now[:status] = :failure 
      flash.now[:result_text] = "Could not create a product"
      flash.now[:messages] = @product.errors.messages
      render :new, status: :bad_request
      return
    end
  end

  def edit 
    @product = Product.find_by(id: params[:id])
    if @product.nil?
      redirect_to products_path
      return
    end
  end

  def update 
    @product = Product.find_by(id: params[:id])
    if @product.nil?
      head :not_found
      return
    elsif @product.update(product_params)
      flash[:status] = :success
      flash[:result_text] = "Successfully updated #{@product.title}"
      redirect_to product_path(@product.id)
      return
    else
      flash.now[:status] = :failure 
      flash.now[:result_text] = "Could not update #{@product.title}"
      flash.now[:messages] = @product.errors.messages 
      render :edit, status: :bad_request
      return
    end
  end

  def add_to_cart
    # find product by the id passed in thru params
    product = Product.find_by(id: params[:id])
    return head :not_found if !product

    # creates a new order if there is no order_id saved to session
    if !@current_order
      order = Order.create(status: "pending")
      session[:order_id] = order.id
    end

    if @current_order && @current_order.products.include?(product)
      order_item = OrderItem.find_by(product_id: product.id)
    else
      # create new order_item
      order_item = OrderItem.new(
        product_id: product.id,
        order_id: session[:order_id],
        quantity: 0,
        shipped: false
      )
    end

    # if quantity is greater than product stock plus existing quantity, don't save order_item
    if params[:quantity].to_i > product.stock - order_item.quantity
      flash[:status] = :failure
      flash[:result_text] = "#{product.title} does not have enough quantity in stock"
      redirect_to product_path(product.id)
      return
    else 
      order_item.quantity += params[:quantity].to_i
      order_item.save
      flash[:status] = :success
      flash[:result_text] = "Successfully added #{product.title} to cart!"
      redirect_to product_path(product.id)
      return
    end
  end

  def index
    if params[:merchant_id]
      # This is the nested route, /merchants/:merchant_id/products
      @merchant = Merchant.find_by(id: params[:merchant_id])
      return head :not_found if !@merchant
      @products = @merchant.products
    elsif params[:category_id]
      @category = Category.find_by(id: params[:category_id])
      return head :not_found if !@category
      @products = @category.products
    else
      # This is the 'regular' route, /products
      @products = Product.all.order(id: :asc)
    end
  end

  def show
    @product = Product.find_by(id: params[:id])
    # saving product into session will allow to add a review for that product
    session[:product] = @product

    if @product.nil?
      redirect_to products_path
      return
    end
  end

  def retire 
    @current_merchant = current_merchant
    @product = Product.find_by(id: params[:id])
    if @product.active
      @product.update(active: false)
      flash[:status] = :success 
      flash[:result_text] = "Successfully retired product #{@product.title}"
      redirect_to product_path(@product.id)
    else
      @product.update(active: true)
      flash[:status] = :success 
      flash[:result_text] = "Successfully activated product #{@product.title}"
      redirect_to product_path(@product.id)
    end
  end


  private 

  def product_params 
    return params.require(:product).permit(:title, :price, :description, :merchant_id,
    :stock, :photo_url, category_ids: []).merge(active: true)
  end
end
