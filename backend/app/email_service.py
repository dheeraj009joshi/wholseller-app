import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import settings
from typing import Optional


async def send_email(
    to_email: str,
    subject: str,
    body: str,
    html_body: Optional[str] = None
) -> bool:
    """
    Send email using SMTP
    """
    if not settings.smtp_user or not settings.smtp_password:
        print("SMTP not configured. Email not sent.")
        return False
    
    try:
        # Create message
        msg = MIMEMultipart('alternative')
        msg['Subject'] = subject
        msg['From'] = f"{settings.smtp_from_name} <{settings.smtp_from_email}>"
        msg['To'] = to_email
        
        # Add body
        part1 = MIMEText(body, 'plain')
        msg.attach(part1)
        
        if html_body:
            part2 = MIMEText(html_body, 'html')
            msg.attach(part2)
        
        # Send email
        with smtplib.SMTP(settings.smtp_host, settings.smtp_port) as server:
            server.starttls()
            server.login(settings.smtp_user, settings.smtp_password)
            server.send_message(msg)
        
        print(f"Email sent to {to_email}")
        return True
    except Exception as e:
        print(f"Error sending email: {e}")
        return False


async def send_welcome_email(user_email: str, user_name: str) -> bool:
    """
    Send welcome email to new user
    """
    subject = "Welcome to Wholeseller!"
    body = f"""
    Hello {user_name},
    
    Welcome to Wholeseller! Your account has been successfully created.
    
    You can now start browsing and purchasing wholesale products.
    
    Best regards,
    Wholeseller Team
    """
    
    html_body = f"""
    <html>
      <body>
        <h2>Welcome to Wholeseller!</h2>
        <p>Hello {user_name},</p>
        <p>Welcome to Wholeseller! Your account has been successfully created.</p>
        <p>You can now start browsing and purchasing wholesale products.</p>
        <p>Best regards,<br>Wholeseller Team</p>
      </body>
    </html>
    """
    
    return await send_email(user_email, subject, body, html_body)


async def send_order_confirmation_email(user_email: str, user_name: str, order_id: str, total: float) -> bool:
    """
    Send order confirmation email
    """
    subject = f"Order Confirmation - {order_id}"
    body = f"""
    Hello {user_name},
    
    Thank you for your order!
    
    Order ID: {order_id}
    Total: ₹{total:.2f}
    
    We will process your order and send you updates.
    
    Best regards,
    Wholeseller Team
    """
    
    html_body = f"""
    <html>
      <body>
        <h2>Order Confirmation</h2>
        <p>Hello {user_name},</p>
        <p>Thank you for your order!</p>
        <p><strong>Order ID:</strong> {order_id}</p>
        <p><strong>Total:</strong> ₹{total:.2f}</p>
        <p>We will process your order and send you updates.</p>
        <p>Best regards,<br>Wholeseller Team</p>
      </body>
    </html>
    """
    
    return await send_email(user_email, subject, body, html_body)
