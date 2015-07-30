require "selenium-webdriver"
require 'rmagick'
include Magick

$wait = Selenium::WebDriver::Wait.new(:timeout => 3)
$driver = Selenium::WebDriver.for :firefox

def is_element_present(how, what)
    $driver.manage.timeouts.implicit_wait = 0
    result = $driver.find_elements(how, what).size() > 0
    if result
        result = $driver.find_element(how, what).displayed?
    end
    $driver.manage.timeouts.implicit_wait = 12
    return result
end

def scripted()
  info = "http://insights.schwab.com/portfolio-management/choose-your-investing-comfort-zone"
  $driver.navigate.to info
  if is_element_present :css, '.infographic-image'
    puts "Passed: Infographic present"
  else
    puts "Failed: Infographic missing"
  end

  fb = $driver.find_element(:xpath, "//li[4]/a/span/i")
  fb.click

  #switches to popup and executes code in brackets, then returns to original
  $driver.switch_to.window ($driver.window_handles.last){
      if $driver.current_url == "https://www.facebook.com/login.php?next=https%3A%2F%2Fwww.facebook.com%2Fsharer%2Fsharer.php%3Fu%3Dhttp%253A%252F%252Finsights.schwab.com%252Fportfolio-management%252Fchoose-your-investing-comfort-zone%26ret%3Dlogin&display=popup"
        puts "Passed: Facebook sharing works"
      else
        puts "Failed: Facebook sharing is broken"
      end
  }

  tw = $driver.find_element(:xpath, "//li[3]/a/span/i")
  tw.click
  $driver.switch_to.window ($driver.window_handles.last){
      if $driver.current_url == "https://twitter.com/intent/tweet?text=Share%3A%20http%3A//insights.schwab.com/portfolio-management/choose-your-investing-comfort-zone%3FSM%3DTwitter&source=webclient"
        puts "Passed: Twitter sharing works"
      else
        puts "Failed: Twitter sharing is broken"
      end
  }
  # $driver.execute_script("scroll(0,900);")
  tw.send_keys :page_down
  check info, 1111

end

def capture (url, page)

  $driver.navigate.to url
  @page = page.to_s

  @verified = File.dirname(__FILE__) + '/screenshots/' + 'verified_' + @page + '.png'

  $driver.save_screenshot(@verified)

end

def check (url, page)

  $driver.navigate.to url

  @page = page.to_s

  @current = File.dirname(__FILE__) + '/screenshots/' + 'current_' + @page + '.png'
  @verified = File.dirname(__FILE__) + '/screenshots/' + 'verified_' + @page + '.png'
  @diff = File.dirname(__FILE__) + '/screenshots/' + 'diff_' + @page + '.png'
  puts @current, @verified

  $driver.save_screenshot(@current)

  a = Image.read( @current ).first
  b = Image.read( @verified ).first

  #Checks if images are identical
  @same = (a <=> b)
  puts @same
  #produces diff image showing discrepencies
  if @same != 0
    @comparePath = 'compare -metric rmse ' + @current + ' ' + @verified  + ' ' + @diff
    system @comparePath
  end
end

$i = 1

def go (compare)

  def take ()
    File.open(File.dirname(__FILE__) + '/urls/' + 'urls.txt', "r") do |f|
      f.each_line do |line|
        compare line, $i
        puts line
        $i += 1
      end
    end
  end
end
##change this to either 'compare' or 'take' or 'scripted' to change action
go (check)
scripted

$driver.close
$driver.quit
